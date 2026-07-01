module ApplicationHelper
  include Pagy::Frontend

  def category_badge_class(category)
    slug = category&.slug.to_s
    "txn-cat txn-cat--#{slug.presence || 'other'}"
  end

  def format_transaction_date(time)
    time.in_time_zone.strftime("%d %b %Y")
  end

  def format_transaction_time(time)
    time.in_time_zone.strftime("%I:%M %p")
  end

  def transaction_filter_params
    params.permit(TransactionFilterService::FILTER_KEYS).to_h.compact_blank
  end
end
