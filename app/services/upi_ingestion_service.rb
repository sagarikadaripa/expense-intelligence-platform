# frozen_string_literal: true

class UpiIngestionService
  def initialize(user)
    @user = user
    @orchestrator = Agents::Orchestrator.new(user: user)
    @repository = TransactionRepository.new(user)
  end

  def ingest!(payload)
    payload = payload.with_indifferent_access
    result = @orchestrator.dispatch("upi_transaction", payload)
    return { success: false, message: result.message } if result.failure?
    if result.data[:duplicate] && !payload[:skip_deduplication]
      return { success: true, duplicate: true }
    end

    if result.requires_approval && !payload[:skip_deduplication]
      return { success: true, pending_approval: true, data: result.data }
    end

    data = result.data
    if payload[:skip_deduplication] && data[:category_id].blank?
      other = Category.for_user(@user).find_by(slug: "other")
      data = data.merge(category_id: other&.id, category_slug: "other")
    end

    transaction = @repository.create_from_agent_result!(data)
    TransactionCreated.publish(transaction)
    { success: true, transaction: transaction }
  rescue ActiveRecord::RecordNotUnique
    existing = @repository.find_existing(result.data)
    return { success: true, transaction: existing } if existing

    raise
  end
end
