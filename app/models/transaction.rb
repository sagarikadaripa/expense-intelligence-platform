# frozen_string_literal: true

class Transaction < ApplicationRecord
  PAYMENT_METHODS = %w[upi cash credit_card debit_card bank_transfer other].freeze
  SOURCES = %w[upi whatsapp manual import].freeze
  STATUSES = %w[completed failed refunded reversed pending].freeze

  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :merchant, optional: true
  belongs_to :related_transaction, class_name: "Transaction", optional: true
  has_many :refund_transactions, class_name: "Transaction", foreign_key: :related_transaction_id

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :currency, :payment_method, :source, :status, :transaction_at, presence: true
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :source, inclusion: { in: SOURCES }
  validates :status, inclusion: { in: STATUSES }

  scope :completed, -> { where(status: "completed") }
  scope :expenses, -> { completed.where("amount_cents > 0") }
  scope :in_period, ->(range) { where(transaction_at: range) }
  scope :by_category, ->(slug) { joins(:category).where(categories: { slug: slug }) }
  scope :above_amount, ->(cents) { where("amount_cents >= ?", cents) }
  scope :recent, -> { order(transaction_at: :desc, id: :desc) }

  def amount
    MoneyValue.new(amount_cents, currency)
  end

  def refund?
    status.in?(%w[refunded reversed])
  end
end
