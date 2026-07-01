# frozen_string_literal: true

module Agents
  class AnomalyAlertAgent < BaseAgent
    protected

    def perform(input)
      user = context.user
      transaction = input[:transaction]
      return Result.ok({ anomaly: false }) unless transaction

      avg = user.transactions.expenses
                .where(transaction_at: 90.days.ago..Time.zone.now)
                .average(:amount_cents).to_f

      threshold = avg * 3
      is_anomaly = transaction[:amount_cents].to_i > threshold && avg.positive?

      if is_anomaly
        Orchestrator.new(user: user).delegate(
          "notification",
          {
            notification_type: "unusual_transaction",
            body: "Unusual transaction of #{MoneyValue.new(transaction[:amount_cents], user.preferred_currency).formatted} detected.",
            anomaly: true
          },
          context: context
        )
      end

      Result.ok({ anomaly: is_anomaly, threshold_cents: threshold.to_i })
    end
  end
end
