# frozen_string_literal: true

class TransactionCreated
  def self.publish(transaction)
    ActiveSupport::Notifications.instrument("transaction.created", transaction: transaction)
    AnomalyDetectionJob.perform_later(transaction.id)
    InsightsGenerationJob.perform_later(transaction.user_id)
  end
end
