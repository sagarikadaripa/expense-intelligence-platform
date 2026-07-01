# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::ParsingAgent do
  let(:user) { create(:user) }
  let(:context) { Agents::Context.new(user: user) }
  let(:agent) { described_class.new(context: context) }

  it "parses amount and category from message" do
    result = agent.call(message: "800 shopping")
    expect(result.data[:amount_cents]).to eq(80_000)
    expect(result.data[:category_hint]).to eq("shopping")
  end

  it "detects payment method" do
    result = agent.call(message: "500 groceries HDFC Card")
    expect(result.data[:payment_method]).to eq("credit_card")
  end
end
