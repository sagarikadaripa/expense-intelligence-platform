# frozen_string_literal: true

module Agents
  class InsightsAgent < BaseAgent
    protected

    def perform(input)
      user = context.user
      current_range, previous_range, period_label = insight_periods(user)
      return Result.ok({ insights: [] }) unless current_range

      current = user.transactions.expenses.in_period(current_range)
      previous = previous_range ? user.transactions.expenses.in_period(previous_range) : none
      insights = [
        spending_summary_insight(current, user, period_label),
        top_category_insight(current, user, period_label),
        spending_growth_insight(current, previous, user, period_label),
        frequent_merchants_insight(current, user, period_label),
        budget_warning(user, current)
      ].compact

      insights.each do |attrs|
        user.insights.create!(attrs) unless duplicate_insight?(user, attrs)
      end

      Result.ok({ insights: insights })
    end

    private

    def none
      Transaction.none
    end

    def insight_periods(user)
      current_month = Time.zone.today.beginning_of_month..Time.zone.now
      if user.transactions.expenses.in_period(current_month).exists?
        return [
          current_month,
          1.month.ago.beginning_of_month..1.month.ago.end_of_month,
          "this month"
        ]
      end

      latest_at = user.transactions.expenses.maximum(:transaction_at)
      return [nil, nil, nil] unless latest_at

      anchor = latest_at.in_time_zone
      month_start = anchor.beginning_of_month
      month_end = anchor.end_of_month
      prev_start = (month_start - 1.month).beginning_of_month
      prev_end = (month_start - 1.month).end_of_month
      label = anchor.strftime("%B %Y")

      [
        month_start..month_end,
        user.transactions.expenses.in_period(prev_start..prev_end).exists? ? (prev_start..prev_end) : nil,
        label
      ]
    end

    def spending_summary_insight(current, user, period_label)
      total = current.sum(:amount_cents)
      count = current.count
      return nil if count.zero?

      {
        insight_type: "spending_summary",
        title: "Spending summary",
        body: "You recorded #{count} #{'transaction'.pluralize(count)} totalling " \
              "#{MoneyValue.new(total, user.preferred_currency).formatted} in #{period_label}.",
        severity: "info"
      }
    end

    def top_category_insight(current, user, period_label)
      top = current.joins(:category).group("categories.name").sum(:amount_cents).max_by { |_, amount| amount }
      return nil unless top

      total = current.sum(:amount_cents)
      share = total.positive? ? ((top[1].to_f / total) * 100).round : 0

      {
        insight_type: "top_category",
        title: "Top category: #{top[0]}",
        body: "#{top[0]} was #{share}% of your spending in #{period_label} " \
              "(#{MoneyValue.new(top[1], user.preferred_currency).formatted}).",
        severity: share >= 40 ? "warning" : "info"
      }
    end

    def spending_growth_insight(current, previous, user, period_label)
      curr_total = current.sum(:amount_cents)
      prev_total = previous.sum(:amount_cents)
      return nil if prev_total.zero?

      growth = ((curr_total - prev_total).to_f / prev_total * 100).round(1)
      return nil if growth.abs < 10

      {
        insight_type: "spending_growth",
        title: growth.positive? ? "Spending increased" : "Spending decreased",
        body: "Spending in #{period_label} is #{growth.abs}% #{growth.positive? ? 'higher' : 'lower'} than the previous month.",
        severity: growth > 25 ? "warning" : "info"
      }
    end

    def frequent_merchants_insight(current, user, period_label)
      top = current.joins(:merchant).group("merchants.name").count.max_by { |_, count| count }
      return nil unless top && top[1] >= 2

      {
        insight_type: "frequent_merchant",
        title: "Frequent merchant: #{top[0]}",
        body: "You paid #{top[0]} #{top[1]} times in #{period_label}.",
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
