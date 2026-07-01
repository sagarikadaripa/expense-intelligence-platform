# frozen_string_literal: true

module Agents
  class Orchestrator
    ROUTING = {
      "upi_transaction" => %w[ingestion reconciliation categorization],
      "whatsapp_message" => %w[whatsapp_conversation],
      "dashboard_report" => %w[analytics visualization reporting],
      "generate_insights" => %w[insights forecasting recommendation],
      "schedule_notifications" => %w[scheduling notification],
      "detect_anomalies" => %w[anomaly_alert notification]
    }.freeze

    def initialize(user: nil)
      @user = user
    end

    def dispatch(intent, input, metadata: {})
      pipeline = ROUTING.fetch(intent.to_s) { [intent.to_s] }
      context = Context.new(user: @user, metadata: metadata)
      accumulated = input.is_a?(Hash) ? input.with_indifferent_access : {}
      last_result = nil

      pipeline.each do |agent_type|
        agent_class = Registry.resolve(agent_type)
        agent = agent_class.new(context: context)
        last_result = agent.call(accumulated)

        if last_result.delegate_to
          delegated = Registry.resolve(last_result.delegate_to).new(context: context)
          last_result = delegated.call(last_result.data)
        end

        break if last_result.failure?

        accumulated = accumulated.merge(last_result.data)
        context = context.with(metadata: context.metadata.merge(last_agent: agent_type))
      end

      return last_result unless last_result&.success?

      Result.ok(accumulated, message: last_result.message)
    end

    def delegate(agent_type, input, context:)
      agent_class = Registry.resolve(agent_type)
      agent_class.new(context: context).call(input.is_a?(Hash) ? input : { value: input })
    end
  end
end
