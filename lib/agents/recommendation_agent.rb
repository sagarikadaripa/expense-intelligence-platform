# frozen_string_literal: true

module Agents
  class RecommendationAgent < BaseAgent
    protected

    def perform(input)
      user = context.user
      range = recommendation_period(user)
      by_category = user.transactions.expenses
                        .in_period(range)
                        .joins(:category).group("categories.name")
                        .sum(:amount_cents)

      recommendations = []
      top = by_category.max_by { |_, amount| amount }
      total = by_category.values.sum

      if top && total.positive?
        share = (top[1].to_f / total * 100).round
        if share >= 25
          recommendations << {
            type: "reduce_category",
            message: "Consider reviewing #{top[0]} spending — it's #{share}% of your expenses in this period."
          }
        end
      end

      detect_subscriptions(user).each do |sub|
        recommendations << {
          type: "subscription_review",
          message: "Recurring charge detected: #{sub[:merchant]} (~#{MoneyValue.new(sub[:amount_cents], user.preferred_currency).formatted}/month)"
        }
      end

      Result.ok({ recommendations: recommendations })
    end

    private

    def recommendation_period(user)
      current_month = Time.zone.today.beginning_of_month..Time.zone.now
      return current_month if user.transactions.expenses.in_period(current_month).exists?

      latest_at = user.transactions.expenses.maximum(:transaction_at)
      return current_month unless latest_at

      anchor = latest_at.in_time_zone
      anchor.beginning_of_month..anchor.end_of_month
    end

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
