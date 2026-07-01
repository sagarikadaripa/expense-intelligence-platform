# frozen_string_literal: true

module Llm
  module Providers
    class Mock
      PATTERNS = {
        /(\d+)\s+(.+)/i => ->(m) { { amount: m[1].to_i, category: m[2].strip, payment_method: "cash" } },
        /swiggy/i => ->(_) { { merchant: "Swiggy", category: "food" } },
        /amazon/i => ->(_) { { merchant: "Amazon", category: "shopping" } }
      }.freeze

      def chat(prompt:, system: nil, json: false)
        PATTERNS.each do |pattern, extractor|
          next unless prompt.match?(pattern)

          data = extractor.call(prompt.match(pattern))
          return json ? data.to_json : data.to_s
        end

        json ? { parsed: false, raw: prompt }.to_json : prompt
      end
    end
  end
end
