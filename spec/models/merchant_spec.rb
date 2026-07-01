# frozen_string_literal: true

require "rails_helper"

RSpec.describe Merchant do
  describe ".find_or_create_by_name!" do
    it "creates a merchant with the original display name" do
      merchant = described_class.find_or_create_by_name!("ZOMATO LIMITED")

      expect(merchant.name).to eq("ZOMATO LIMITED")
      expect(merchant.normalized_name).to eq("zomato limited")
    end

    it "returns the existing merchant for the same normalized name" do
      existing = described_class.create!(name: "Swiggy", normalized_name: "swiggy")

      merchant = described_class.find_or_create_by_name!("SWIGGY")

      expect(merchant).to eq(existing)
    end

    it "returns nil for blank names" do
      expect(described_class.find_or_create_by_name!("   ")).to be_nil
    end
  end
end
