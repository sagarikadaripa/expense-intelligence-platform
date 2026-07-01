# frozen_string_literal: true

module Categorization
  class HistoricalStrategy
    def initialize(user:, input:, llm: nil)
      @user = user
      @input = input
    end

    def call
      merchant_name = @input[:merchant_name] || @input[:description]
      return { confidence: 0.0 } if merchant_name.blank?

      merchant = Merchant.find_by(normalized_name: Merchant.normalize_name(merchant_name))
      return { confidence: 0.0 } unless merchant

      recent = @user.transactions
                    .where(merchant: merchant)
                    .where.not(category_id: nil)
                    .order(transaction_at: :desc)
                    .limit(5)

      return { confidence: 0.0 } if recent.empty?

      top_category_id = recent.group(:category_id).count.max_by { |_, count| count }&.first
      category = Category.find_by(id: top_category_id)
      return { confidence: 0.0 } unless category

      { category_id: category.id, slug: category.slug, confidence: 0.85 }
    end
  end
end
