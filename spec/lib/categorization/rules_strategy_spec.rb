# frozen_string_literal: true

require "rails_helper"

RSpec.describe Categorization::RulesStrategy do
  let(:user) { create(:user) }

  before do
    create(:category, slug: "food", name: "Food")
    create(:category, slug: "transport", name: "Transport")
    create(:category, slug: "other", name: "Other")
  end

  it "categorizes groceries merchants" do
    create(:category, slug: "groceries", name: "Groceries")

    expect(described_class.new(user: user, input: { merchant_name: "ZEPTO" }).call[:slug]).to eq("groceries")
    expect(described_class.new(user: user, input: { merchant_name: "BLINKIT" }).call[:slug]).to eq("groceries")
    expect(described_class.new(user: user, input: { merchant_name: "INSTAMART" }).call[:slug]).to eq("groceries")
  end

  it "categorizes shopping merchants" do
    create(:category, slug: "shopping", name: "Shopping")

    expect(described_class.new(user: user, input: { merchant_name: "AMAZON" }).call[:slug]).to eq("shopping")
    expect(described_class.new(user: user, input: { merchant_name: "FLIPKART" }).call[:slug]).to eq("shopping")
    expect(described_class.new(user: user, input: { merchant_name: "MYNTRA" }).call[:slug]).to eq("shopping")
    expect(described_class.new(user: user, input: { merchant_name: "AJIO" }).call[:slug]).to eq("shopping")
    expect(described_class.new(user: user, input: { merchant_name: "NYKAA" }).call[:slug]).to eq("shopping")
  end

  it "categorizes food merchants" do
    result = described_class.new(user: user, input: { merchant_name: "ZOMATO LIMITED" }).call

    expect(result[:slug]).to eq("food")
  end

  it "categorizes transport merchants" do
    result = described_class.new(user: user, input: { merchant_name: "BMRCL HOPEFARM CHANNASANDRA" }).call

    expect(result[:slug]).to eq("transport")
  end

  it "categorizes entertainment merchants" do
    create(:category, slug: "entertainment", name: "Entertainment")

    expect(described_class.new(user: user, input: { merchant_name: "GOOGLE YOUTUBE" }).call[:slug]).to eq("entertainment")
    expect(described_class.new(user: user, input: { merchant_name: "JIOHOTSTAR" }).call[:slug]).to eq("entertainment")
    expect(described_class.new(user: user, input: { merchant_name: "NETFLIX" }).call[:slug]).to eq("entertainment")
    expect(described_class.new(user: user, input: { description: "Spotify music subscription" }).call[:slug]).to eq("entertainment")
    expect(described_class.new(user: user, input: { merchant_name: "BOOKMYSHOW" }).call[:slug]).to eq("entertainment")
    expect(described_class.new(user: user, input: { merchant_name: "DISTRICT EVENTS" }).call[:slug]).to eq("entertainment")
  end

  it "categorizes travel merchants as transport" do
    expect(described_class.new(user: user, input: { merchant_name: "CLEARTRIP PRIVATE LIMITED" }).call[:slug]).to eq("transport")
    expect(described_class.new(user: user, input: { merchant_name: "GOIBIBO" }).call[:slug]).to eq("transport")
    expect(described_class.new(user: user, input: { merchant_name: "MAKE MY TRIP" }).call[:slug]).to eq("transport")
    expect(described_class.new(user: user, input: { merchant_name: "IXIGO" }).call[:slug]).to eq("transport")
    expect(described_class.new(user: user, input: { merchant_name: "INDIGO" }).call[:slug]).to eq("transport")
    expect(described_class.new(user: user, input: { merchant_name: "AIR INDIA" }).call[:slug]).to eq("transport")
  end

  it "categorizes health and fitness merchants" do
    create(:category, slug: "health_fitness", name: "Health/Fitness")

    expect(described_class.new(user: user, input: { merchant_name: "CULT FIT" }).call[:slug]).to eq("health_fitness")
    expect(described_class.new(user: user, input: { merchant_name: "CULTFIT" }).call[:slug]).to eq("health_fitness")
  end

  it "categorizes rent payments" do
    create(:category, slug: "rent", name: "Rent")
    expect(described_class.new(user: user, input: { description: "Flat rent March" }).call[:slug]).to eq("rent")
    expect(described_class.new(user: user, input: { merchant_name: "LANDLORD PAYMENT" }).call[:slug]).to eq("rent")
  end

  it "categorizes vehicle registration style merchants as transport" do
    result = described_class.new(user: user, input: { merchant_name: "KA01 AB 1234" }).call

    expect(result[:slug]).to eq("transport")
  end

  it "returns no match for unknown merchants" do
    result = described_class.new(user: user, input: { merchant_name: "LIVPURE SMART HOMES PRIVATE LIMITED" }).call

    expect(result[:confidence]).to eq(0.0)
  end
end
