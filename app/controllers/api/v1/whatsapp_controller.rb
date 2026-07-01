# frozen_string_literal: true

module Api
  module V1
    class WhatsappController < BaseController
      skip_before_action :authenticate_api_user!, only: [:webhook]
      before_action :verify_webhook_signature, only: [:webhook]

      def webhook
        user = User.find_by_whatsapp!(webhook_params[:from])
        result = WhatsappMessageService.new(user).process!(webhook_params[:message])

        if result[:reply]
          ::Whatsapp::Client.new.send_message(to: user.whatsapp_number, body: result[:reply])
        end

        head :ok
      rescue ActiveRecord::RecordNotFound
        head :not_found
      end

      private

      def webhook_params
        params.permit(:from, :message)
      end

      def verify_webhook_signature
        return if Rails.env.development?

        token = request.headers["X-Webhook-Token"]
        head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(
          token.to_s, ENV.fetch("WHATSAPP_WEBHOOK_TOKEN", "")
        )
      end
    end
  end
end
