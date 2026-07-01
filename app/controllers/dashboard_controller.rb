# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @period = params[:period] || "year"
    @tab = params[:tab].presence_in(%w[overview transactions import insights]) || "overview"
    @dashboard = DashboardService.new(current_user).build(period: @period)
    @insights = current_user.insights.active.recent.limit(10)
    if @tab == "transactions"
      @transaction_filter = TransactionFilterService.new(current_user, params)
      @pagy, @transactions = pagy(
        @transaction_filter.call,
        limit: 20,
        path: dashboard_path({ tab: "transactions" }.merge(@transaction_filter.to_h))
      )
    else
      @transactions = current_user.transactions.expenses.recent.limit(10)
    end
    @import = current_user.statement_imports.find_by(id: params[:import_id]) if params[:import_id].present?
  end
end
