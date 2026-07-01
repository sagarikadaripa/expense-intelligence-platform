# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionFilterService do
  let(:user) { create(:user) }
  let!(:food) { create(:category, slug: "food", name: "Food") }
  let!(:transport) { create(:category, slug: "transport", name: "Transport/Travel") }

  let!(:swiggy) do
    create(:transaction, user: user, category: food, description: "Paid to Swiggy",
                           payment_method: "upi", source: "import",
                           transaction_at: Time.zone.parse("2026-02-01 12:00"))
  end

  let!(:uber) do
    create(:transaction, user: user, category: transport, description: "Paid to Uber",
                           payment_method: "upi", source: "manual",
                           transaction_at: Time.zone.parse("2026-02-15 18:30"))
  end

  describe "#call" do
    it "returns all expenses when no filters are set" do
      results = described_class.new(user, {}).call

      expect(results).to contain_exactly(swiggy, uber)
    end

    it "filters by search text" do
      results = described_class.new(user, { q: "swiggy" }).call

      expect(results).to contain_exactly(swiggy)
    end

    it "filters by category" do
      results = described_class.new(user, { category_id: transport.id }).call

      expect(results).to contain_exactly(uber)
    end

    it "filters by date range" do
      results = described_class.new(user, { from: "2026-02-10", to: "2026-02-20" }).call

      expect(results).to contain_exactly(uber)
    end

    it "filters by payment method and source" do
      results = described_class.new(user, { payment_method: "upi", source: "manual" }).call

      expect(results).to contain_exactly(uber)
    end
  end

  describe "#active?" do
    it "is false with no filters" do
      expect(described_class.new(user, {})).not_to be_active
    end

    it "is true when a filter is present" do
      expect(described_class.new(user, { q: "uber" })).to be_active
    end
  end
end
