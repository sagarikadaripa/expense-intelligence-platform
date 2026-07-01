# frozen_string_literal: true

class UpiId < ApplicationRecord
  belongs_to :user

  validates :upi_id, presence: true, format: { with: /\A[\w.\-]+@[\w.\-]+\z/ }
  validates :upi_id, uniqueness: { scope: :user_id }

  before_validation :normalize_upi_id

  scope :verified, -> { where.not(verified_at: nil) }

  private

  def normalize_upi_id
    self.upi_id = upi_id.to_s.strip.downcase if upi_id.present?
  end
end
