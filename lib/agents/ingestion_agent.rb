# frozen_string_literal: true

module Agents
  class IngestionAgent < BaseAgent
    protected

    def perform(input)
      payload = input.with_indifferent_access
      normalized = {
        amount_cents: (payload[:amount].to_f * 100).to_i,
        currency: payload[:currency] || context.user&.preferred_currency || "INR",
        description: payload[:description],
        upi_reference: payload[:upi_reference] || payload[:reference],
        external_id: payload[:external_id],
        transaction_at: parse_time(payload[:transaction_at]),
        payment_method: payload[:payment_method].presence_in(Transaction::PAYMENT_METHODS) || "upi",
        source: payload[:source].presence_in(Transaction::SOURCES) || "upi",
        status: map_status(payload[:status]),
        metadata: payload[:metadata] || {}
      }

      normalized[:fingerprint] = build_fingerprint(normalized, skip_deduplication: payload[:skip_deduplication])
      Result.ok(normalized, message: "Transaction normalized")
    end

    private

    def parse_time(value)
      return value.in_time_zone if value.respond_to?(:in_time_zone) && !value.is_a?(String)
      return Time.zone.parse(value.to_s) if value.present?

      Time.current
    end

    def map_status(status)
      case status.to_s.downcase
      when "failed", "failure" then "failed"
      when "refund", "refunded" then "refunded"
      when "reversed", "reversal" then "reversed"
      else "completed"
      end
    end

    def build_fingerprint(data, skip_deduplication: false)
      if skip_deduplication && data[:external_id].present?
        return Digest::SHA256.hexdigest([context.user&.id, "import", data[:external_id]].join("|"))
      end

      Digest::SHA256.hexdigest([
        context.user&.id,
        data[:upi_reference],
        data[:amount_cents],
        data[:transaction_at]&.to_i
      ].compact.join("|"))
    end
  end
end
