# frozen_string_literal: true

module Agents
  class InsightsAgent < BaseAgent
    protected

    def perform(input)
      user = context.user
      current = user.transactions.expenses.in_period(Time.zone.today.beginning_of_month..Time.zone.now)
      previous = user.transactions.expenses.in_period(
        1.month.ago.beginning_of_month..1.month.ago.end_of_month
      )

      insights = []
      insights << spending_growth_insight(current, previous, user)
      insights << frequent_merchants_insight(current, user)
      insights << budget_warning(user, current)
      insights.compact!

      insights.each do |attrs|
        user.insights.create!(attrs) unless duplicate_insight?(user, attrs)
      end

      Result.ok({ insights: insights })
    end

    private

    def spending_growth_insight(current, previous, user)
      curr_total = current.sum(:amount_cents)
      prev_total = previous.sum(:amount_cents)
      return nil if prev_total.zero?

      growth = ((curr_total - prev_total).to_f / prev_total * 100).round(1)
      return nil if growth.abs < 10

      {
        insight_type: "spending_growth",
        title: growth.positive? ? "Spending increased" : "Spending decreased",
        body: "Your spending is #{growth.abs}% #{growth.positive? ? 'higher' : 'lower'} than last month.",
        severity: growth > 25 ? "warning" : "info"
      }
    end

    def frequent_merchants_insight(current, user)
      top = current.joins(:merchant).group("merchants.name").count.max_by { |_, c| c }
      return nil unless top

      {
        insight_type: "frequent_merchant",
        title: "Frequent merchant: #{top[0]}",
        body: "You visited #{top[0]} #{top[1]} times this month.",
        severity: "info"
      }
    end

    def budget_warning(user, current)
      budget = user.monthly_budget_cents
      return nil unless budget

      spent = current.sum(:amount_cents)
      ratio = spent.to_f / budget
      return nil if ratio < 0.8

      {
        insight_type: "budget_warning",
        title: "Budget alert",
        body: "You've used #{(ratio * 100).round}% of your monthly budget.",
        severity: ratio >= 1 ? "critical" : "warning"
      }
    end

    def duplicate_insight?(user, attrs)
      user.insights.active.exists?(insight_type: attrs[:insight_type], title: attrs[:title])
    end
  end
end
