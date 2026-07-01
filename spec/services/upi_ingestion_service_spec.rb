# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpiIngestionService do
  let(:user) { create(:user, :with_upi) }

  before do
    create(:category, slug: "food", name: "Food")
  end

  it "creates a transaction from UPI payload" do
    result = described_class.new(user).ingest!(
      amount: 250,
      description: "Zomato lunch",
      upi_reference: "REF123"
    )

    expect(result[:success]).to be true
    expect(user.transactions.count).to eq(1)
  end
end
