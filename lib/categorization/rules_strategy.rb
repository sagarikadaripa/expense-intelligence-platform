# frozen_string_literal: true

module Categorization
  class RulesStrategy
    FOOD_PATTERNS = [
      /swiggy/i,
      /zomato/i,
      /swish/i,
      /\bbistro\b/i,
      /boba\s*bhai/i,
      /domino'?s?/i,
      /\bpizza\b/i
    ].freeze

    GROCERIES_PATTERNS = [
      /zepto/i,
      /blinkit/i,
      /instamart/i,
      /bigbasket/i
    ].freeze

    SHOPPING_PATTERNS = [
      /amazon/i,
      /flipkart/i,
      /myntra/i,
      /\bajio\b/i,
      /nykaa/i,
      /meesho/i
    ].freeze

    TRANSPORT_PATTERNS = [
      /\buber\b/i,
      /\brapido\b/i,
      /\bola\b/i,
      /\bbmrcl\b/i,
      /\bbmtc\b/i,
      /\bmetro\b/i,
      /\bKA[\s-]*\d{2}\b/i,
      /cleartrip/i,
      /goibibo/i,
      /make\s*my\s*trip/i,
      /makemytrip/i,
      /\bmmt\b/i,
      /ixigo/i,
      /\bindigo\b/i,
      /air\s*india/i
    ].freeze

    RENT_PATTERNS = [
      /\brent\b/i,
      /\bhousing\b/i,
      /\blandlord\b/i,
      /\blease\b/i,
      /\bflat\s*rent\b/i
    ].freeze

    HEALTH_FITNESS_PATTERNS = [
      /cult\.?\s*fit/i,
      /\bcult\b/i
    ].freeze

    ENTERTAINMENT_PATTERNS = [
      /youtube/i,
      /jio\s*hotstar/i,
      /jiohotstar/i,
      /\bhotstar\b/i,
      /netflix/i,
      /spotify/i,
      /\bmusic\b/i,
      /\bdistrict\b/i,
      /bookmyshow/i,
      /book\s*my\s*show/i
    ].freeze

    def initialize(user:, input:, llm: nil)
      @user = user
      @input = input
    end

    def call
      text = [@input[:merchant_name], @input[:description]].compact.join(" ")
      return category_for("food", 0.95) if FOOD_PATTERNS.any? { |pattern| text.match?(pattern) }
      return category_for("groceries", 0.95) if GROCERIES_PATTERNS.any? { |pattern| text.match?(pattern) }
      return category_for("shopping", 0.95) if SHOPPING_PATTERNS.any? { |pattern| text.match?(pattern) }
      return category_for("transport", 0.95) if TRANSPORT_PATTERNS.any? { |pattern| text.match?(pattern) }
      return category_for("health_fitness", 0.95) if HEALTH_FITNESS_PATTERNS.any? { |pattern| text.match?(pattern) }
      return category_for("entertainment", 0.95) if ENTERTAINMENT_PATTERNS.any? { |pattern| text.match?(pattern) }
      return category_for("rent", 0.95) if RENT_PATTERNS.any? { |pattern| text.match?(pattern) }

      { confidence: 0.0 }
    end

    private

    def category_for(slug, confidence)
      category = Category.for_user(@user).find_by(slug: slug)
      return { confidence: 0.0 } unless category

      { category_id: category.id, slug: category.slug, confidence: confidence }
    end
  end
end
