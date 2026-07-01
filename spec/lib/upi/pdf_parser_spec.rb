# frozen_string_literal: true

require "rails_helper"

RSpec.describe Upi::PdfParser do
  let(:sample_text) do
    <<~TEXT
      Jan 03, 2026, 03:36 PM
      Paid to SWAMY KN
      Transaction ID: T2601031536295992101536
      UTR No: 195539614808
      Debited from XX4015
      Debit
      INR 44.00
      Jan 03, 2026, 06:51 PM
      Received from Desai Kavina Hemantkumar
      Transaction ID: T2601031851427607818800
      UTR No: 636916773129
      Credited to XX4015
      Credit
      INR 21250.00
      Jan 04, 2026, 12:25 PM
      Paid to jagadeeshan a
      Transaction ID: T2601041225006162091572
      UTR No: 894458519749
      Debited from XX4015
      Debit
      INR 44.00
    TEXT
  end

  it "parses Google Pay table-style PDF text with amount on the paid-to line" do
    text = <<~TEXT
      Transaction statement
      02 Jan, 2026 Paid to Hritesh Jaiswal ₹200
      11:07 AM UPI Transaction ID 600214708611 Paid by Federal Bank 4015
      04 Jan, 2026 Paid to CAFE AMUDHAM ₹165
      12:28 PM UPI Transaction ID 600425440301 Paid by Federal Bank 4015
      04 Jan, 2026 Received from Google Pay rewards ₹1
      03:55 PM UPI Transaction ID 798614790046 Paid by Federal Bank 4015
    TEXT

    results = described_class.parse_text(text, source: "google_pay")

    expect(results.size).to eq(2)
    expect(results.map { |r| r[:merchant_name] }).to eq(["Hritesh Jaiswal", "CAFE AMUDHAM"])
    expect(results.map { |r| r[:amount_cents] }).to eq([20_000, 16_500])
  end

  it "parses Google Pay PDF text and skips credits" do
    text = <<~TEXT
      02 Jan, 2026
      11:07 AM
      Paid to Hritesh Jaiswal
      UPI Transaction ID 600214708611
      Paid by Federal Bank 4015
      ₹200
      04 Jan, 2026
      12:28 PM
      Paid to CAFE AMUDHAM
      UPI Transaction ID 600425440301
      Paid by Federal Bank 4015
      ₹165
      04 Jan, 2026
      03:55 PM
      Received from Google Pay rewards
      UPI Transaction ID 798614790046
      Paid to Federal Bank 4015
      ₹1
    TEXT

    results = described_class.parse_text(text, source: "google_pay")

    expect(results.size).to eq(2)
    expect(results.map { |r| r[:merchant_name] }).to eq(["Hritesh Jaiswal", "CAFE AMUDHAM"])
    expect(results.map { |r| r[:amount_cents] }).to eq([20_000, 16_500])
    expect(results.first[:external_id]).to eq("600214708611")
    expect(results.first[:source]).to eq("google_pay")
  end

  it "parses PhonePe PDF text with spaced colons" do
    text = <<~TEXT
      Jan 03, 2026       Paid to SWAMY KN                                                    Debit     INR 44.00
      03:36 PM
      Transaction ID : T2601031536295992101536
      UTR No : 195539614808
    TEXT

    result = described_class.parse_text(text).first

    expect(result[:merchant_name]).to eq("SWAMY KN")
    expect(result[:external_id]).to eq("T2601031536295992101536")
    expect(result[:upi_reference]).to eq("195539614808")
  end

  it "parses PhonePe table-style PDF text with split columns" do
    table_text = <<~TEXT
      Jan 03, 2026   Paid to SWAMY KN                                             Debi INR
      03:36 PM       Transaction ID: T2601031536295992101536                      t     44.00
      UTR No: 195539614808
      Jan 03, 2026   Received from Desai Kavina Hemantkumar                       Cre   INR
      06:51 PM       Transaction ID: T2601031851427607818800                      dit   21250.00
      Jan 04, 2026   Paid to jagadeeshan a                                        Debi INR
      12:25 PM       Transaction ID: T2601041225006162091572                      t     44.00
      UTR No: 894458519749
    TEXT

    results = described_class.parse_text(table_text)

    expect(results.size).to eq(2)
    expect(results.map { |r| r[:merchant_name] }).to eq(["SWAMY KN", "jagadeeshan a"])
    expect(results.map { |r| r[:amount_cents] }).to eq([4400, 4400])
  end

  it "parses debit transactions and skips credits" do
    results = described_class.parse_text(sample_text)

    expect(results.size).to eq(2)
    expect(results.map { |r| r[:merchant_name] }).to eq(["SWAMY KN", "jagadeeshan a"])
    expect(results.map { |r| r[:amount_cents] }).to eq([4400, 4400])
    expect(results.first[:external_id]).to eq("T2601031536295992101536")
    expect(results.first[:upi_reference]).to eq("195539614808")
    expect(results.first[:metadata][:import]).to eq("pdf")
  end

  it "routes PDF files through ImportParser" do
    file = instance_double(ActionDispatch::Http::UploadedFile, original_filename: "statement.pdf", path: "/tmp/statement.pdf")
    allow(Upi::PdfParser).to receive(:parse).and_return([])

    Upi::ImportParser.parse(file)

    expect(Upi::PdfParser).to have_received(:parse).with(file, source: nil)
  end
end
