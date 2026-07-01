# frozen_string_literal: true

module Upi
  class ImportParser
    def self.parse(file, source: nil)
      extension = File.extname(file.original_filename.to_s).downcase

      case extension
      when ".pdf"
        PdfParser.parse(file, source: source)
      else
        CsvParser.parse(file, source: source)
      end
    end
  end
end
