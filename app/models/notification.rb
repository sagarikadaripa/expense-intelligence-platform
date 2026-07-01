# frozen_string_literal: true

class Notification < ApplicationRecord
  STATUSES = %w[pending scheduled sent failed cancelled].freeze
  CHANNELS = %w[whatsapp email push].freeze

  belongs_to :user

  validates :notification_type, :channel, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :channel, inclusion: { in: CHANNELS }

  scope :pending_delivery, -> { where(status: %w[pending scheduled]).where("scheduled_at IS NULL OR scheduled_at <= ?", Time.current) }
end
