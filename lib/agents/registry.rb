# frozen_string_literal: true

module Agents
  class Registry
    AGENT_MAP = {
      "ingestion" => "Agents::IngestionAgent",
      "categorization" => "Agents::CategorizationAgent",
      "reconciliation" => "Agents::ReconciliationAgent",
      "parsing" => "Agents::ParsingAgent",
      "whatsapp_conversation" => "Agents::WhatsappConversationAgent",
      "command" => "Agents::CommandAgent",
      "analytics" => "Agents::AnalyticsAgent",
      "visualization" => "Agents::VisualizationAgent",
      "reporting" => "Agents::ReportingAgent",
      "insights" => "Agents::InsightsAgent",
      "forecasting" => "Agents::ForecastingAgent",
      "recommendation" => "Agents::RecommendationAgent",
      "notification" => "Agents::NotificationAgent",
      "scheduling" => "Agents::SchedulingAgent",
      "anomaly_alert" => "Agents::AnomalyAlertAgent"
    }.freeze

    class << self
      def boot!
        AGENT_MAP.each_value { |klass| klass.constantize }
      end

      def resolve(type)
        klass_name = AGENT_MAP.fetch(type.to_s) { raise ArgumentError, "Unknown agent: #{type}" }
        klass_name.constantize
      end

      def types
        AGENT_MAP.keys
      end
    end
  end
end
