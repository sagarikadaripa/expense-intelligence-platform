# frozen_string_literal: true

class Budget < ApplicationRecord
  PERIODS = %w[weekly monthly yearly].freeze

  belongs_to :user
  belongs_to :category, optional: true

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :period, inclusion: { in: PERIODS }

  def amount
    MoneyValue.new(amount_cents, user.preferred_currency)
  end
end
