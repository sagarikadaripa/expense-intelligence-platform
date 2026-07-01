# frozen_string_literal: true

module Api
  module V1
    class UpiTransactionsController < BaseController
      def create
        service = UpiIngestionService.new(current_user)
        result = service.ingest!(upi_params)
        status = result[:duplicate] ? :ok : :created
        render json: result, status: status
      end

      private

      def upi_params
        params.permit(:amount, :currency, :description, :upi_reference, :external_id,
                      :transaction_at, :status, :merchant_name, metadata: {})
      end
    end
  end
end
