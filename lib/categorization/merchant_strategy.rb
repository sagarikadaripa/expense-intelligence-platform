# frozen_string_literal: true

module Categorization
  class MerchantStrategy
    MERCHANT_MAP = {
      "zepto" => "groceries",
      "blinkit" => "groceries",
      "instamart" => "groceries",
      "bigbasket" => "groceries",
      "amazon" => "shopping",
      "flipkart" => "shopping",
      "myntra" => "shopping",
      "ajio" => "shopping",
      "nykaa" => "shopping",
      "meesho" => "shopping"
    }.freeze

    def initialize(user:, input:, llm: nil)
      @user = user
      @input = input
    end

    def call
      text = [@input[:description], @input[:merchant_name]].compact.join(" ").downcase
      slug = MERCHANT_MAP.find { |merchant, _| text.include?(merchant) }&.last
      category = Category.for_user(@user).find_by(slug: slug) if slug
      return { confidence: 0.0 } unless category

      { category_id: category.id, slug: category.slug, confidence: 0.9 }
    end
  end
end
