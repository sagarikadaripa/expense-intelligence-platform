# frozen_string_literal: true

module Whatsapp
  class Client
    def send_message(to:, body:)
      if Rails.env.development? || ENV["WHATSAPP_PROVIDER"] == "mock"
        Rails.logger.info("[WhatsApp Mock] To: #{to} — #{body}")
        return { success: true }
      end

      conn = Faraday.new(url: ENV.fetch("WHATSAPP_API_URL")) do |f|
        f.request :json
        f.response :json
        f.adapter Faraday.default_adapter
        f.headers["Authorization"] = "Bearer #{ENV.fetch('WHATSAPP_API_TOKEN')}"
      end

      conn.post("/messages", { to: to, body: body })
    end
  end
end
