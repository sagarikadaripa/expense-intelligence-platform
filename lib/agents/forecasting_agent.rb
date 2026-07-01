# frozen_string_literal: true

module Agents
  class ForecastingAgent < BaseAgent
    protected

    def perform(input)
      user = context.user
      days_elapsed = Time.zone.today.day
      days_in_month = Time.zone.today.end_of_month.day
      spent = user.transactions.expenses
                  .in_period(Time.zone.today.beginning_of_month..Time.zone.now)
                  .sum(:amount_cents)

      daily_avg = spent.to_f / [days_elapsed, 1].max
      projected = (daily_avg * days_in_month).to_i
      budget = user.monthly_budget_cents

      risk = budget ? (projected > budget ? "high" : projected > budget * 0.9 ? "medium" : "low") : "unknown"

      Result.ok(
        {
          projected_monthly_cents: projected,
          daily_average_cents: daily_avg.to_i,
          budget_risk: risk,
          days_remaining: days_in_month - days_elapsed
        },
        message: "Projected monthly spend: #{MoneyValue.new(projected, user.preferred_currency).formatted}"
      )
    end
  end
end
