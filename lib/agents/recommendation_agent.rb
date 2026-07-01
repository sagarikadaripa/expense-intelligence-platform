# frozen_string_literal: true

module Agents
  class RecommendationAgent < BaseAgent
    protected

    def perform(input)
      user = context.user
      by_category = user.transactions.expenses
                        .in_period(Time.zone.today.beginning_of_month..Time.zone.now)
                        .joins(:category).group("categories.slug").sum(:amount_cents)

      recommendations = []
      top = by_category.max_by { |_, v| v }
      if top && top[1] > user.monthly_budget_cents.to_i * 0.3
        recommendations << {
          type: "reduce_category",
          message: "Consider reducing #{top[0]} spending — it's #{((top[1].to_f / by_category.values.sum) * 100).round}% of your expenses."
        }
      end

      subscriptions = detect_subscriptions(user)
      subscriptions.each do |sub|
        recommendations << {
          type: "subscription_review",
          message: "Recurring charge detected: #{sub[:merchant]} (~#{MoneyValue.new(sub[:amount_cents], user.preferred_currency).formatted}/month)"
        }
      end

      Result.ok({ recommendations: recommendations })
    end

    private

    def detect_subscriptions(user)
      user.transactions.expenses
          .where(transaction_at: 3.months.ago..Time.zone.now)
          .joins(:merchant)
          .group("merchants.name", :amount_cents)
          .having("COUNT(*) >= 3")
          .count
          .map { |(merchant, amount), count| { merchant: merchant, amount_cents: amount, occurrences: count } }
    end
  end
end
