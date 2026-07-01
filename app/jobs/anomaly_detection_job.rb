# frozen_string_literal: true

class AnomalyDetectionJob < ApplicationJob
  queue_as :analytics

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)
    ::Agents::Orchestrator.new(user: transaction.user).dispatch(
      "detect_anomalies",
      { transaction: { amount_cents: transaction.amount_cents, id: transaction.id } }
    )
  end
end
