# frozen_string_literal: true

class ConversationMessage < ApplicationRecord
  ROLES = %w[user assistant system].freeze

  belongs_to :conversation_session

  validates :role, :content, presence: true
  validates :role, inclusion: { in: ROLES }
end
