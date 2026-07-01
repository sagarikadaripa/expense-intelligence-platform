# frozen_string_literal: true

class StatementImport < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  belongs_to :user
  has_one_attached :file

  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def percent_complete
    return 100 if status == "completed"
    return 0 if total_count.zero?

    ((processed_count.to_f / total_count) * 100).round
  end

  def in_progress?
    status.in?(%w[pending processing])
  end

  def mark_processing!(total:)
    update!(status: "processing", total_count: total, processed_count: 0, imported_count: 0, error_message: nil)
  end

  def tick_progress!(imported: false)
    attrs = { processed_count: processed_count + 1 }
    attrs[:imported_count] = imported_count + 1 if imported
    update!(attrs)
  end

  def mark_completed!
    update!(status: "completed", processed_count: total_count)
  end

  def mark_failed!(message)
    update!(status: "failed", error_message: message)
  end
end
