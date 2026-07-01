# frozen_string_literal: true

module Agents
  class VisualizationAgent < BaseAgent
    protected

    def perform(input)
      analytics = input[:by_category] ? input : input
      charts = {
        category_pie: pie_chart(analytics[:by_category] || {}),
        payment_bar: bar_chart(analytics[:by_payment_method] || {}),
        daily_line: line_chart(analytics[:daily_totals] || {}),
        merchant_bar: bar_chart(analytics[:by_merchant] || {})
      }

      Result.ok({ charts: charts })
    end

    private

    def pie_chart(data)
      data.map { |label, cents| { label: label, value: cents / 100.0 } }
    end

    def bar_chart(data)
      data.map { |label, cents| { label: label.to_s, value: cents / 100.0 } }
    end

    def line_chart(data)
      data.sort_by { |date, _| date }.map { |date, cents| { date: date.to_s, value: cents / 100.0 } }
    end
  end
end
