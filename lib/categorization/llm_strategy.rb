# frozen_string_literal: true

module Categorization
  class LlmStrategy
    def initialize(user:, input:, llm:)
      @user = user
      @input = input
      @llm = llm
    end

    def call
      categories = Category.for_user(@user).pluck(:slug).join(", ")
      prompt = <<~PROMPT
        Categorize this expense into one of: #{categories}.
        Description: #{@input[:description]}
        Amount: #{@input[:amount_cents]}
        Respond with JSON: {"slug": "...", "confidence": 0.0-1.0}
      PROMPT

      response = @llm.chat(prompt: prompt, json: true)
      parsed = JSON.parse(response) rescue { "slug" => "other", "confidence" => 0.5 }
      category = Category.for_user(@user).find_by(slug: parsed["slug"]) ||
                 Category.for_user(@user).find_by(slug: "other")

      { category_id: category&.id, slug: category&.slug || "other", confidence: parsed["confidence"].to_f }
    end
  end
end
