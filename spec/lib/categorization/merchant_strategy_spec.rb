# frozen_string_literal: true

require "rails_helper"

RSpec.describe Categorization::MerchantStrategy do
  let(:user) { create(:user) }
  let!(:food) { create(:category, slug: "food", name: "Food") }
  let!(:shopping) { create(:category, slug: "shopping", name: "Shopping") }

  it "categorizes by merchant name" do
    create(:category, slug: "food", name: "Food")

    result = described_class.new(
      user: user,
      input: { description: "Payment to Amazon" }
    ).call

    expect(result[:slug]).to eq("shopping")
    expect(result[:confidence]).to be >= 0.8
  end
end
