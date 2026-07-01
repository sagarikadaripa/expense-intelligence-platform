# frozen_string_literal: true

class StatementImportService
  def initialize(user)
    @user = user
    @upi_ingestion = UpiIngestionService.new(user)
  end

  def import!(file, source: nil, statement_import: nil)
    transactions = Upi::ImportParser.parse(file, source: source)
    if transactions.empty?
      message = empty_file_message(file)
      statement_import&.mark_failed!(message)
      return { success: false, error: message }
    end

    statement_import&.mark_processing!(total: transactions.size)

    imported = 0
    errors = []

    transactions.each do |attrs|
      result = @upi_ingestion.ingest!(
        amount: attrs[:amount_cents] / 100.0,
        description: attrs[:description],
        merchant_name: attrs[:merchant_name],
        transaction_at: attrs[:transaction_at],
        status: attrs[:status],
        external_id: attrs[:external_id],
        upi_reference: attrs[:upi_reference],
        metadata: attrs[:metadata],
        source: "import",
        skip_deduplication: true
      )

      imported += 1 if result[:success]
      errors << result[:message] if result[:message] && !result[:success]
      statement_import&.tick_progress!(imported: result[:success])
    end

    statement_import&.mark_completed!

    {
      success: true,
      imported: imported,
      total: transactions.size,
      errors: errors
    }
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
    statement_import&.mark_failed!(e.message)
    { success: false, error: "Could not read PDF: #{e.message}" }
  end

  private

  def empty_file_message(file)
    if File.extname(file.original_filename.to_s).downcase == ".pdf"
      text = PDF::Reader.new(file.path).pages.map(&:text).join
      if text.strip.length < 50
        return "Could not read text from this PDF. Download the statement PDF from Google Pay or PhonePe (not a screenshot or photo)."
      end
    elsif File.extname(file.original_filename.to_s).downcase == ".csv"
      return "CSV must use columns: date, description, amount. Download the template from the Import tab."
    end

    "No transactions found in file"
  end
end
