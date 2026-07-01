# frozen_string_literal: true

class ExportsController < ApplicationController
  before_action :authenticate_user!

  def show
    service = ExportService.new(current_user)
    period = parse_period

    case params[:format_type]
    when "pdf"
      send_data service.to_pdf(period: period),
                filename: "expenses-#{Date.current}.pdf",
                type: "application/pdf"
    else
      send_data service.to_csv(period: period),
                filename: "expenses-#{Date.current}.csv",
                type: "text/csv"
    end
  end

  private

  def parse_period
    return nil unless params[:period] == "month"

    Time.zone.today.beginning_of_month..Time.zone.now
  end
end
