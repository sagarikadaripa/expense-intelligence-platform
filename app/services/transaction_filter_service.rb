# frozen_string_literal: true

class TransactionFilterService
  FILTER_KEYS = %i[q category_id from to payment_method source].freeze

  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    scope = @user.transactions.expenses.recent
    scope = filter_by_search(scope)
    scope = filter_by_category(scope)
    scope = filter_by_date_range(scope)
    scope = filter_by_payment_method(scope)
    scope = filter_by_source(scope)
    scope
  end

  def active?
    to_h.any?
  end

  def to_h
    FILTER_KEYS.index_with { |key| @params[key].presence }.compact
  end

  private

  def filter_by_search(scope)
    query = @params[:q].to_s.strip
    return scope if query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    scope.left_joins(:merchant).where(
      "transactions.description ILIKE :query OR merchants.name ILIKE :query",
      query: pattern
    )
  end

  def filter_by_category(scope)
    category_id = @params[:category_id].presence
    return scope if category_id.blank?

    scope.where(category_id: category_id)
  end

  def filter_by_date_range(scope)
    from = parse_date(@params[:from])
    to = parse_date(@params[:to])

    if from && to
      scope.in_period(from.beginning_of_day..to.end_of_day)
    elsif from
      scope.where(transaction_at: from.beginning_of_day..)
    elsif to
      scope.where(transaction_at: ..to.end_of_day)
    else
      scope
    end
  end

  def filter_by_payment_method(scope)
    payment_method = @params[:payment_method].presence
    return scope if payment_method.blank?
    return scope unless Transaction::PAYMENT_METHODS.include?(payment_method)

    scope.where(payment_method: payment_method)
  end

  def filter_by_source(scope)
    source = @params[:source].presence
    return scope if source.blank?
    return scope unless Transaction::SOURCES.include?(source)

    scope.where(source: source)
  end

  def parse_date(value)
    return if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
