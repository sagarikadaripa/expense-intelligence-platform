# frozen_string_literal: true

class TransactionRepository
  def initialize(user)
    @user = user
  end

  def create_from_agent_result!(data)
    merchant = Merchant.find_or_create_by_name!(data[:merchant_name]) if data[:merchant_name].present?
    @user.transactions.create!(
      amount_cents: data[:amount_cents],
      currency: data[:currency] || @user.preferred_currency,
      category_id: data[:category_id],
      merchant: merchant,
      payment_method: data[:payment_method] || "upi",
      source: data[:source] || "upi",
      status: data[:status] || "completed",
      description: data[:description],
      transaction_at: data[:transaction_at] || Time.current,
      upi_reference: data[:upi_reference],
      external_id: data[:external_id],
      fingerprint: data[:fingerprint],
      related_transaction_id: data[:related_transaction_id],
      metadata: data[:metadata] || {}
    )
  end

  def find_existing(data)
    scope = @user.transactions
    if data[:external_id].present?
      found = scope.find_by(external_id: data[:external_id])
      return found if found
    end

    scope.find_by(fingerprint: data[:fingerprint]) if data[:fingerprint].present?
  end
end
