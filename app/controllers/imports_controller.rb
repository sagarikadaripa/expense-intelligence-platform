# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :authenticate_user!

  ALLOWED_TYPES = %w[.csv .pdf].freeze

  def create
    unless params[:file].present?
      redirect_to dashboard_path(tab: "import"), alert: "Please select a file to import."
      return
    end

    extension = File.extname(params[:file].original_filename).downcase
    unless ALLOWED_TYPES.include?(extension)
      redirect_to dashboard_path(tab: "import"), alert: "Only CSV and PDF files are supported."
      return
    end

    statement_import = current_user.statement_imports.create!(
      source: params[:source].presence,
      status: "pending"
    )
    statement_import.file.attach(params[:file])
    StatementImportJob.perform_later(statement_import.id)

    redirect_to dashboard_path(tab: "import", import_id: statement_import.id)
  end

  def show
    statement_import = current_user.statement_imports.find(params[:id])

    render json: {
      status: statement_import.status,
      percent: statement_import.percent_complete,
      processed: statement_import.processed_count,
      total: statement_import.total_count,
      imported: statement_import.imported_count,
      error: statement_import.error_message
    }
  end
end
