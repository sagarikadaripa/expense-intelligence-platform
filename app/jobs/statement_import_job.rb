# frozen_string_literal: true

class StatementImportJob < ApplicationJob
  queue_as :default

  def perform(statement_import_id)
    statement_import = StatementImport.find(statement_import_id)
    return unless statement_import.file.attached?

    statement_import.file.open do |tempfile|
      uploaded = ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: statement_import.file.filename.to_s,
        type: statement_import.file.content_type
      )

      StatementImportService.new(statement_import.user).import!(
        uploaded,
        source: statement_import.source,
        statement_import: statement_import
      )
    end
  rescue StandardError => e
    statement_import&.mark_failed!(e.message)
    raise
  end
end
