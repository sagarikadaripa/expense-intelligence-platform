# frozen_string_literal: true

module Llm
  module Providers
    class Openai
      def initialize
        @conn = Faraday.new(url: "https://api.openai.com") do |f|
          f.request :json
          f.response :json
          f.adapter Faraday.default_adapter
          f.headers["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
        end
      end

      def chat(prompt:, system: nil, json: false)
        messages = []
        messages << { role: "system", content: system } if system.present?
        messages << { role: "user", content: prompt }

        body = { model: ENV.fetch("OPENAI_MODEL", "gpt-4o-mini"), messages: messages }
        body[:response_format] = { type: "json_object" } if json

        response = @conn.post("/v1/chat/completions", body)
        response.body.dig("choices", 0, "message", "content")
      end
    end
  end
end
