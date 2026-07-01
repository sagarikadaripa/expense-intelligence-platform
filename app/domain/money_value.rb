# frozen_string_literal: true

MoneyValue = Data.define(:cents, :currency) do
  def to_f
    cents / 100.0
  end

  def formatted
    symbol = currency == "INR" ? "₹" : currency
    "#{symbol}#{format('%.2f', to_f)}"
  end
end
