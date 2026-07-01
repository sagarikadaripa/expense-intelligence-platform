# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManualTransactionService do
  let(:user) { create(:user) }

  before do
    create(:category, slug: "food", name: "Food")
    create(:category, slug: "other", name: "Other")
  end

  it "creates a manual transaction" do
    transaction = described_class.new(user).create!(
      amount: 250,
      merchant_name: "Swiggy",
      payment_method: "upi",
      transaction_at: "2026-06-15"
    )

    expect(transaction.source).to eq("manual")
    expect(transaction.amount_cents).to eq(25_000)
    expect(transaction.category.slug).to eq("food")
  end

  it "uses the selected category when provided" do
    other = Category.find_by!(slug: "other")

    transaction = described_class.new(user).create!(
      amount: 100,
      category_id: other.id,
      description: "Misc"
    )

    expect(transaction.category).to eq(other)
  end
end
