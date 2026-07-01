# frozen_string_literal: true

class ManualTransactionService
  def initialize(user)
    @user = user
  end

  def create!(attrs)
    raise ArgumentError, "Amount must be greater than zero" if attrs[:amount].to_f <= 0

    category_id = resolve_category_id(attrs)
    merchant = Merchant.find_or_create_by_name!(attrs[:merchant_name]) if attrs[:merchant_name].present?

    transaction = @user.transactions.create!(
      amount_cents: (attrs[:amount].to_f * 100).to_i,
      currency: @user.preferred_currency,
      category_id: category_id,
      merchant: merchant,
      payment_method: attrs[:payment_method].presence || "cash",
      source: "manual",
      status: "completed",
      description: attrs[:description].presence || attrs[:merchant_name].presence || "Manual expense",
      transaction_at: parse_time(attrs[:transaction_at])
    )

    TransactionCreated.publish(transaction)
    transaction
  end

  def update!(transaction, attrs)
    raise ArgumentError, "Amount must be greater than zero" if attrs.key?(:amount) && attrs[:amount].to_f <= 0

    updates = {}
    updates[:amount_cents] = (attrs[:amount].to_f * 100).to_i if attrs.key?(:amount)
    updates[:description] = attrs[:description] if attrs.key?(:description)
    updates[:category_id] = attrs[:category_id] if attrs.key?(:category_id)
    updates[:payment_method] = attrs[:payment_method] if attrs[:payment_method].present?
    updates[:transaction_at] = merge_transaction_date(transaction.transaction_at, attrs[:transaction_at]) if attrs.key?(:transaction_at)

    if attrs.key?(:merchant_name)
      merchant = attrs[:merchant_name].present? ? Merchant.find_or_create_by_name!(attrs[:merchant_name]) : nil
      updates[:merchant] = merchant
      updates[:description] = attrs[:description].presence || attrs[:merchant_name].presence || transaction.description
    end

    transaction.update!(updates)
    transaction
  end

  private

  def resolve_category_id(attrs)
    return attrs[:category_id] if attrs[:category_id].present?

    result = Categorization::RulesStrategy.new(
      user: @user,
      input: {
        merchant_name: attrs[:merchant_name],
        description: attrs[:description]
      }
    ).call

    return result[:category_id] if result[:category_id].present?

    Category.for_user(@user).find_by(slug: "other")&.id
  end

  def parse_time(value)
    return Time.zone.now if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    Time.zone.now
  end

  def merge_transaction_date(existing_time, date_value)
    return parse_time(date_value) if existing_time.blank?

    new_date = Date.parse(date_value.to_s)
    existing_time.in_time_zone.change(year: new_date.year, month: new_date.month, day: new_date.day)
  rescue ArgumentError
    parse_time(date_value)
  end
end
