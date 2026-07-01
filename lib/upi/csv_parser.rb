# frozen_string_literal: true

require "csv"

module Upi
  class CsvParser
    STANDARD_HEADERS = %w[date description amount].freeze

    def self.parse(file, source: nil)
      new(file, source: source).parse
    end

    def initialize(file, source: nil)
      @file = file
      @source = source
    end

    def parse
      rows = CSV.read(@file.path, headers: true, liberal_parsing: true)
      return [] if rows.empty?

      headers = rows.headers.map { |h| h.to_s.downcase.strip }
      return [] unless standard_format?(headers)

      rows.filter_map { |row| parse_row(row, headers) }
    end

    private

    def standard_format?(headers)
      STANDARD_HEADERS.all? { |required| headers.any? { |h| h == required || h.include?(required) } }
    end

    def parse_row(row, headers)
      amount = parse_amount(fetch(row, headers, "amount"))
      return nil unless amount&.positive?

      description = fetch(row, headers, "description").to_s.strip
      return nil if description.blank?

      {
        amount_cents: (amount * 100).to_i,
        description: description,
        merchant_name: description,
        transaction_at: parse_datetime(fetch(row, headers, "date")),
        status: "completed",
        source: @source || "import",
        metadata: { import: "standard_csv" }
      }
    end

    def fetch(row, headers, name)
      idx = headers.index { |h| h == name || h.include?(name) }
      idx ? row[idx] : nil
    end

    def parse_amount(value)
      return nil if value.blank?

      cleaned = value.to_s.gsub(/[₹,\s]/, "").gsub(/dr$/i, "")
      amount = cleaned.to_f
      amount.positive? ? amount : nil
    end

    def parse_datetime(value)
      return Time.zone.now if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      Time.zone.now
    end
  end
end
