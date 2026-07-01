# frozen_string_literal: true

module Api
  module V1
    class DashboardController < BaseController
      def show
        data = DashboardService.new(current_user).build(period: params[:period] || "month")
        render json: data
      end
    end
  end
end
