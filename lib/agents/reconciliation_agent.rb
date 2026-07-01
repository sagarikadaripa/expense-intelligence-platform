# frozen_string_literal: true

module Agents
  class ReconciliationAgent < BaseAgent
    protected

    def perform(input)
      user = context.user
      return Result.ok(input.merge(duplicate: false), message: "Reconciliation passed") if input[:skip_deduplication]

      fingerprint = input[:fingerprint]
      external_id = input[:external_id]

      duplicate = Transaction.find_by(user: user, fingerprint: fingerprint) if fingerprint.present?
      duplicate ||= Transaction.find_by(user: user, external_id: external_id) if external_id.present?

      if duplicate
        return Result.ok({ duplicate: true, existing_id: duplicate.id }, message: "Duplicate detected")
      end

      if input[:status].in?(%w[refunded reversed]) && input[:related_reference].present?
        original = Transaction.find_by(user: user, upi_reference: input[:related_reference])
        input = input.merge(related_transaction_id: original&.id)
      end

      Result.ok(input.merge(duplicate: false), message: "Reconciliation passed")
    end
  end
end
