# frozen_string_literal: true

class InsightsGenerationJob < ApplicationJob
  queue_as :analytics

  def perform(user_id)
    user = User.find(user_id)
    ::Agents::Orchestrator.new(user: user).dispatch("generate_insights", {})
  end
end
