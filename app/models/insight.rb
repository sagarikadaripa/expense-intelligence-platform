# frozen_string_literal: true

class Insight < ApplicationRecord
  SEVERITIES = %w[info warning critical].freeze

  belongs_to :user

  validates :insight_type, :title, :body, :severity, presence: true
  validates :severity, inclusion: { in: SEVERITIES }

  scope :active, -> { where(dismissed_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
end
