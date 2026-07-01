# frozen_string_literal: true

require "pdf/reader"

module Upi
  class PdfParser
    PHONEPE_DATE_TIME = '[A-Z][a-z]{2} \d{1,2}, \d{4}, \d{1,2}:\d{2} (?:AM|PM)'
    GOOGLE_PAY_DATE_TIME = '\d{1,2} [A-Z][a-z]{2}, \d{4}, \d{1,2}:\d{2} (?:AM|PM)'
    DATE_TIME_PATTERN = "(?:#{PHONEPE_DATE_TIME}|#{GOOGLE_PAY_DATE_TIME})"
    DATE_TIME = /(#{DATE_TIME_PATTERN})/i
    GOOGLE_DATE = /(\d{1,2} [A-Z][a-z]{2}, \d{4})/
    PHONEPE_DATE = /([A-Z][a-z]{2} \d{1,2}, \d{4})/
    TIME_OF_DAY = /(\d{1,2}:\d{2}\s*(?:AM|PM))/i
    PAID_TO = /Paid to (.+?)(?:\s+(?:UPI )?Transaction ID\s*:|(?:\s+Debi(?:t)?)|(?:\s+Cre(?:dit)?)|\s+Debit|\s+Credit|\s+Paid by|\z)/i
    RECEIVED_FROM = /Received from (.+?)(?:\s+(?:UPI )?Transaction ID\s*:|(?:\s+Debi(?:t)?)|(?:\s+Cre(?:dit)?)|\s+Debit|\s+Credit|\s+Paid by|\z)/i
    TXN_ID = /Transaction ID\s*:\s*(\S+)/i
    UPI_TXN_ID = /UPI Transaction ID\s*:?\s*(\S+)/i
    UTR = /UTR No\s*:\s*(\S+)/i
    TYPE = /\b(Debit|Credit)\b/i
    AMOUNT_PATTERNS = [
      /₹\s*([\d,]+(?:\.\d{2})?)/,
      /(?:Rs\.?|INR)\s*([\d,]+(?:\.\d{2})?)/i,
      /\b(\d[\d,]+\.\d{2})\b/
    ].freeze

    def self.parse(file, source: nil)
      new(file, source: source).parse
    end

    def self.parse_text(text, source: nil)
      new(nil, source: source).parse_text(text)
    end

    def initialize(file, source: nil)
      @file = file
      @source = source
    end

    def parse
      parse_text(extract_text)
    end

    def parse_text(text)
      @format = detect_source(text)
      @source = @format if @source.blank?
      normalized = normalize(text)

      transactions = parse_google_pay(normalized) if @format == "google_pay"
      transactions = parse_by_date_blocks(normalized) if transactions.blank?
      transactions = parse_by_action_blocks(normalized) if transactions.blank?
      transactions = parse_google_pay(normalized.gsub(/\n+/, " ")) if transactions.blank? && @format == "google_pay"

      transactions
    end

    private

    def google_pay?
      @format == "google_pay"
    end

    def detect_source(text)
      if text.match?(/UPI Transaction ID|Google Pay|Transaction statement/i) ||
         text.match?(/\d{1,2} [A-Z][a-z]{2}, \d{4}/)
        "google_pay"
      else
        "phonepe"
      end
    end

    def extract_text
      reader = PDF::Reader.new(@file.path)
      reader.pages.map(&:text).join("\n")
    end

    def normalize(text)
      text = text.to_s.gsub(/\r\n?/, "\n")
      text = text.tr("\u00A0", " ")

      # Google Pay: date and time on consecutive lines.
      text = text.gsub(
        /(\d{1,2} [A-Z][a-z]{2}, \d{4})\s*\n\s*(\d{1,2}:\d{2} (?:AM|PM))/m,
        '\1, \2'
      )

      # Google Pay table rows: amount on the same line as "Paid to", time on the next line.
      text = text.gsub(
        /(\d{1,2} [A-Z][a-z]{2}, \d{4})(.*?Paid to .+?(?:₹|Rs\.?|INR)\s*[\d,]+(?:\.\d{2})?)\s*\n\s*(\d{1,2}:\d{2} (?:AM|PM))/mi,
        '\1, \3 \2'
      )
      text = text.gsub(
        /(\d{1,2} [A-Z][a-z]{2}, \d{4})(.*?Received from .+?(?:₹|Rs\.?|INR)\s*[\d,]+(?:\.\d{2})?)\s*\n\s*(\d{1,2}:\d{2} (?:AM|PM))/mi,
        '\1, \3 \2'
      )

      # PhonePe table PDFs often split the time onto the next line.
      text = text.gsub(
        /([A-Z][a-z]{2} \d{1,2}, \d{4})([^\n]*)\n\s*(\d{1,2}:\d{2} (?:AM|PM))/m,
        '\1, \3\2'
      )

      text = text.gsub(/Debi\s*t\b/i, "Debit")
      text = text.gsub(/Debi\s+INR/i, "Debit INR")
      text = text.gsub(/Cre\s*dit\b/i, "Credit")
      text = text.gsub(/Cre\s+INR/i, "Credit INR")
      text = text.gsub(
        /Transaction ID\s*:\s*(\S+)\s+t\s+([\d,]+\.\d{2})/i,
        'Transaction ID: \1 Debit INR \2'
      )
      text = text.gsub(
        /Transaction ID\s*:\s*(\S+)\s+dit\s+([\d,]+\.\d{2})/i,
        'Transaction ID: \1 Credit INR \2'
      )
      text = text.gsub(/INR\s+(\d[\d,]*\.\d{2})/m, "INR \\1")
      text = text.gsub(/INR\s*\n\s*([\d,]+\.\d{2})/m, "INR \\1")
      text = text.gsub(/INR\s+t\s+([\d,]+\.\d{2})/m, "INR \\1")
      text = text.gsub(/INR\s+dit\s+([\d,]+\.\d{2})/m, "INR \\1")
      text = text.gsub(/(?:₹|Rs\.?)\s*\n\s*([\d,]+(?:\.\d{2})?)/m, '₹\1')

      text.gsub(/[ \t]+/, " ")
    end

    def parse_google_pay(text)
      transactions = []

      text.to_enum(:scan, /(?:Paid to|Received from)\s+/i).each do
        match = Regexp.last_match
        action = match[0]
        start = match.begin(0)
        nxt = text.index(/(?:Paid to|Received from)\s+/i, match.end(0))
        segment = text[start...nxt]
        lookback = text[[start - 120, 0].max...start]

        txn = build_google_pay_transaction(segment, lookback)
        transactions << txn if txn
      end

      transactions
    end

    def build_google_pay_transaction(segment, lookback = "")
      chunk = [lookback, segment].join(" ")
      credit = segment.match?(/^Received from/i)

      merchant = segment[PAID_TO, 1] || segment[RECEIVED_FROM, 1]
      merchant = clean_merchant(merchant)
      txn_id = chunk[UPI_TXN_ID, 1] || chunk[TXN_ID, 1]
      amount = extract_amount(chunk)
      datetime = resolve_datetime(chunk)

      return nil if credit
      return nil unless amount&.positive?
      return nil unless datetime

      {
        amount_cents: (amount * 100).to_i,
        description: merchant.present? ? "Paid to #{merchant}" : "UPI payment",
        merchant_name: merchant,
        transaction_at: datetime,
        status: "completed",
        source: @source,
        external_id: txn_id,
        upi_reference: chunk[UTR, 1],
        metadata: { import: "pdf", transaction_id: txn_id }
      }
    end

    def parse_by_date_blocks(text)
      transactions = []

      text.scan(/(#{DATE_TIME_PATTERN})(.*?)(?=#{DATE_TIME_PATTERN}|\z)/mi) do |date, body|
        txn = build_transaction(date, body)
        transactions << txn if txn
      end

      transactions
    end

    def parse_by_action_blocks(text)
      transactions = []

      text.to_enum(:scan, /(Paid to|Received from)\s+/i).each do
        match = Regexp.last_match
        action = match[1]
        start = match.end(0)
        nxt = text.index(/(Paid to|Received from)\s+/i, start)
        body = text[start...nxt]
        lookback = text[[match.begin(0) - 120, 0].max...match.begin(0)]
        chunk = "#{action} #{body}"
        date_line = preceding_date(text, match.begin(0)) || chunk[DATE_TIME, 1]
        date_line ||= resolve_datetime_string(lookback + chunk)
        txn = build_transaction(date_line, chunk)
        transactions << txn if txn
      end

      transactions
    end

    def preceding_date(text, position)
      text[0...position].scan(DATE_TIME).last&.first
    end

    def build_transaction(date_line, body)
      chunk = [date_line, body].compact.join(" ")
      type = nil
      merchant = nil

      if (match = chunk.match(PAID_TO))
        merchant = clean_merchant(match[1])
      elsif chunk.match?(RECEIVED_FROM)
        type = "credit"
      end

      type ||= chunk[TYPE, 1]&.downcase
      type ||= "debit" if chunk.match?(/\bDebi\b/i)
      type ||= "credit" if chunk.match?(/\bCre\b/i) || chunk.match?(RECEIVED_FROM)
      amount = extract_amount(chunk)
      amount ||= parse_amount(chunk[/\bt\s+([\d,]+\.\d{2})/, 1])
      amount ||= parse_amount(chunk[/\bdit\s+([\d,]+\.\d{2})/, 1])
      datetime = date_line.present? ? parse_datetime(date_line) : resolve_datetime(chunk)

      return nil unless amount&.positive?
      return nil if type == "credit"
      return nil unless datetime

      txn_id = chunk[TXN_ID, 1] || chunk[UPI_TXN_ID, 1]

      {
        amount_cents: (amount * 100).to_i,
        description: merchant.present? ? "Paid to #{merchant}" : "UPI payment",
        merchant_name: merchant,
        transaction_at: datetime,
        status: "completed",
        source: @source,
        external_id: txn_id,
        upi_reference: chunk[UTR, 1],
        metadata: { import: "pdf", transaction_id: txn_id, utr: chunk[UTR, 1] }
      }
    end

    def resolve_datetime(chunk)
      string = resolve_datetime_string(chunk)
      parse_datetime(string) if string.present?
    end

    def resolve_datetime_string(chunk)
      if (match = chunk.match(DATE_TIME))
        return match[1]
      end

      date = chunk[GOOGLE_DATE, 1] || chunk[PHONEPE_DATE, 1]
      time = chunk[TIME_OF_DAY, 1]
      return nil unless date && time

      "#{date}, #{time}"
    end

    def extract_amount(text)
      AMOUNT_PATTERNS.each do |pattern|
        amount = parse_amount(text[pattern, 1])
        return amount if amount&.positive?
      end

      nil
    end

    def clean_merchant(name)
      name.to_s.strip
          .sub(/\s+(?:₹|Rs\.?|INR)\s*[\d,]+(?:\.\d{2})?\s*\z/i, "")
          .strip
    end

    def parse_amount(value)
      return nil if value.blank?

      value.to_s.delete(",").to_f
    end

    def parse_datetime(value)
      value = value.strip
      [
        "%b %d, %Y, %I:%M %p",
        "%d %b, %Y, %I:%M %p"
      ].each do |format|
        return Time.zone.strptime(value, format)
      rescue ArgumentError
        next
      end

      Time.zone.parse(value) || Time.zone.now
    end
  end
end
