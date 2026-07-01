# frozen_string_literal: true

module Agents
  class ParsingAgent < BaseAgent
    PAYMENT_PATTERNS = {
      /hdfc\s*card/i => "credit_card",
      /icici\s*card/i => "credit_card",
      /debit\s*card/i => "debit_card",
      /cash/i => "cash",
      /upi/i => "upi"
    }.freeze

    protected

    def perform(input)
      message = input[:message].to_s.strip
      parsed = parse_with_rules(message) || parse_with_llm(message)

      Result.ok(parsed, message: parsed[:complete] ? "Parsed expense" : "Needs clarification")
    end

    private

    def parse_with_rules(message)
      match = message.match(/\A(\d+(?:\.\d{1,2})?)\s+(.+)\z/i)
      return nil unless match

      amount = (match[1].to_f * 100).to_i
      remainder = match[2].strip
      payment_method = detect_payment_method(remainder)
      remainder = remainder.gsub(/hdfc\s*card|icici\s*card|debit\s*card|cash|upi/i, "").strip

      parts = remainder.split(/\s+/)
      merchant = parts.length > 1 ? parts.first.titleize : nil
      category_hint = parts.length > 1 ? parts[1..].join(" ") : remainder

      {
        amount_cents: amount,
        category_hint: category_hint.downcase,
        merchant_name: merchant,
        payment_method: payment_method,
        description: remainder,
        complete: category_hint.present?
      }
    end

    def parse_with_llm(message)
      response = llm.chat(
        prompt: "Parse expense message: #{message}. Return JSON with amount, category, merchant, payment_method.",
        json: true
      )
      data = JSON.parse(response) rescue {}
      {
        amount_cents: (data["amount"].to_f * 100).to_i,
        category_hint: data["category"],
        merchant_name: data["merchant"],
        payment_method: data["payment_method"] || "cash",
        description: message,
        complete: data["category"].present?
      }
    end

    def detect_payment_method(text)
      PAYMENT_PATTERNS.each { |pattern, method| return method if text.match?(pattern) }
      "cash"
    end
  end
end
