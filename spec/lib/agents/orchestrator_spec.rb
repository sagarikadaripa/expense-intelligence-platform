# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Orchestrator do
  let(:user) { create(:user, :with_upi) }

  before do
    %w[food transport shopping other].each do |slug|
      create(:category, slug: slug, name: slug.titleize)
    end
  end

  describe "#dispatch upi_transaction" do
    it "ingests and categorizes a transaction" do
      result = described_class.new(user: user).dispatch(
        "upi_transaction",
        { amount: 450, description: "Swiggy order", upi_reference: "UPI001" }
      )

      expect(result).to be_success
      expect(result.data[:category_slug]).to eq("food")
    end

    it "detects duplicates" do
      orchestrator = described_class.new(user: user)
      orchestrator.dispatch("upi_transaction", { amount: 100, description: "test", upi_reference: "DUP1" })
      result = orchestrator.dispatch("upi_transaction", { amount: 100, description: "test", upi_reference: "DUP1" })

      expect(result.data[:duplicate]).to be true
    end
  end
end
