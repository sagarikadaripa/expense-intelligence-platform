# frozen_string_literal: true

module Agents
  class CategorizationAgent < BaseAgent
    STRATEGIES = [
      Categorization::RulesStrategy,
      Categorization::MerchantStrategy,
      Categorization::HistoricalStrategy
    ].freeze

    protected

    def perform(input)
      return Result.delegate("notification", input) if input[:duplicate] && !input[:skip_deduplication]

      user = context.user
      category = classify(user, input)

      if category[:confidence].to_f < 0.6 && !input[:skip_deduplication]
        return Result.approval_required(
          input.merge(suggested_category: category),
          message: "Low confidence classification requires review"
        )
      end

      Result.ok(
        input.merge(
          category_id: category[:category_id],
          category_slug: category[:slug],
          category_confidence: category[:confidence]
        ),
        message: "Categorized as #{category[:slug]}"
      )
    end

    private

    def default_category(user)
      category = Category.for_user(user).find_by(slug: "other")
      {
        category_id: category&.id,
        slug: category&.slug || "other",
        confidence: 0.5
      }
    end

    def classify(user, input)
      STRATEGIES.each do |strategy_class|
        result = strategy_class.new(user: user, input: input, llm: llm).call
        return result if result[:confidence].to_f >= 0.8
      end

      default_category(user)
    end
  end
end
