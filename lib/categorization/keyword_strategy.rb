# frozen_string_literal: true

module Categorization
  class KeywordStrategy
    KEYWORDS = {
      "food" => %w[food lunch dinner breakfast coffee restaurant],
      "groceries" => %w[groceries grocery vegetables fruits],
      "transport" => %w[fuel petrol diesel cab taxi metro bus flight airline travel cleartrip goibibo makemytrip ixigo indigo],
      "health_fitness" => %w[gym fitness cult workout health pharmacy hospital clinic medicine],
      "shopping" => %w[shopping clothes apparel electronics],
      "rent" => %w[rent housing],
      "utilities" => %w[electricity water gas internet broadband],
      "entertainment" => %w[youtube netflix hotstar jiohotstar spotify music subscription streaming district bookmyshow event ticket]
    }.freeze

    def initialize(user:, input:, llm: nil)
      @user = user
      @input = input
    end

    def call
      text = @input[:description].to_s.downcase
      match = KEYWORDS.find { |_slug, words| words.any? { |w| text.include?(w) } }
      return { confidence: 0.0 } unless match

      category = Category.for_user(@user).find_by(slug: match.first)
      return { confidence: 0.0 } unless category

      { category_id: category.id, slug: category.slug, confidence: 0.75 }
    end
  end
end
