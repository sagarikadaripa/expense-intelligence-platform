# frozen_string_literal: true

class ExportService
  def initialize(user)
    @user = user
  end

  def to_csv(period: nil)
    txns = scope(period)
    CSV.generate(headers: true) do |csv|
      csv << %w[Date Amount Currency Category Merchant PaymentMethod Source Description Status]
      txns.find_each do |t|
        csv << [
          t.transaction_at.iso8601,
          t.amount.to_f,
          t.currency,
          t.category&.name,
          t.merchant&.name,
          t.payment_method,
          t.source,
          t.description,
          t.status
        ]
      end
    end
  end

  def to_pdf(period: nil)
    txns = scope(period)
    pdf = Prawn::Document.new
    pdf.text "Expense Report — #{@user.name}", size: 18, style: :bold
    pdf.move_down 10
    pdf.text "Generated: #{Time.zone.now.strftime('%d %b %Y %H:%M')}"
    pdf.move_down 20

    rows = [["Date", "Amount", "Category", "Merchant", "Method"]]
    txns.limit(500).each do |t|
      rows << [
        t.transaction_at.strftime("%d %b"),
        t.amount.formatted,
        t.category&.name,
        t.merchant&.name,
        t.payment_method
      ]
    end
    pdf.table(rows, header: true, width: pdf.bounds.width)
    pdf.render
  end

  private

  def scope(period)
    scope = @user.transactions.expenses.recent
    scope = scope.in_period(period) if period
    scope
  end
end
