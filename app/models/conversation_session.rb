# frozen_string_literal: true

class ConversationSession < ApplicationRecord
  belongs_to :user
  has_many :conversation_messages, dependent: :destroy

  STATES = %w[idle awaiting_category awaiting_payment_method awaiting_confirmation editing].freeze

  validates :channel, :state, presence: true
  validates :state, inclusion: { in: STATES }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def reset!
    update!(state: "idle", context: {}, expires_at: 1.hour.from_now)
  end

  def store_context!(key, value)
    update!(context: context.merge(key.to_s => value))
  end
end
