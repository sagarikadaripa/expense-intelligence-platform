# frozen_string_literal: true

module Agents
  class AnalyticsAgent < BaseAgent
    protected

    def perform(input)
      period = input[:period] || "month"
      range = period_range(period)
      txns = context.user.transactions.expenses.in_period(range)

      Result.ok(
        {
          period: period,
          total_cents: txns.sum(:amount_cents),
          count: txns.count,
          by_category: group_by_category(txns),
          by_payment_method: txns.group(:payment_method).sum(:amount_cents),
          by_merchant: group_by_merchant(txns),
          daily_totals: daily_totals(txns),
          largest: txns.order(amount_cents: :desc).limit(5).map { |t| serialize(t) }
        }
      )
    end

    private

    def period_range(period)
      case period
      when "day" then Time.zone.today.all_day
      when "week" then Time.zone.today.beginning_of_week..Time.zone.now
      when "year" then Time.zone.today.beginning_of_year..Time.zone.now
      when "all" then Time.zone.parse("2000-01-01")..Time.zone.now
      else Time.zone.today.beginning_of_month..Time.zone.now
      end
    end

    def group_by_category(txns)
      txns.left_joins(:category)
          .group(Arel.sql("COALESCE(categories.slug, 'other')"))
          .sum(:amount_cents)
    end

    def group_by_merchant(txns)
      txns.left_joins(:merchant)
          .group(Arel.sql("COALESCE(merchants.name, 'Unknown')"))
          .sum(:amount_cents)
    end

    def daily_totals(txns)
      txns.group("DATE(transaction_at)").sum(:amount_cents)
    end

    def serialize(txn)
      { id: txn.id, amount_cents: txn.amount_cents, description: txn.description, at: txn.transaction_at }
    end
  end
end
