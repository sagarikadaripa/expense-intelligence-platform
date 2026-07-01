# frozen_string_literal: true

module Agents
  class ReportingAgent < BaseAgent
    protected

    def perform(input)
      total = input[:total_cents].to_i
      currency = context.user.preferred_currency
      by_category = input[:by_category] || {}

      top_category = by_category.max_by { |_, v| v }
      narrative = build_narrative(total, currency, top_category, input[:count].to_i)

      Result.ok(
        {
          narrative: narrative,
          summary: {
            total: MoneyValue.new(total, currency).formatted,
            transaction_count: input[:count],
            top_category: top_category&.first,
            period: input[:period]
          }
        }
      )
    end

    private

    def build_narrative(total, currency, top_category, count)
      formatted = MoneyValue.new(total, currency).formatted
      parts = ["You spent #{formatted} across #{count} transactions"]
      if top_category
        cat_amount = MoneyValue.new(top_category[1], currency).formatted
        parts << "with #{top_category[0]} being your top category at #{cat_amount}"
      end
      "#{parts.join(', ')}."
    end
  end
end
