# frozen_string_literal: true

module Agents
  class BaseAgent
    attr_reader :context

    def self.agent_type
      name.demodulize.underscore.gsub(/_agent$/, "")
    end

    def initialize(context:)
      @context = context
    end

    def call(input)
      task = create_task(input)
      task.update!(status: "running")
      result = perform(input)
      persist_result(task, result)
      result
    rescue StandardError => e
      task&.fail!(e.message)
      Rails.logger.error("[#{self.class.name}] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      Result.fail(e.message)
    end

    protected

    def perform(_input)
      raise NotImplementedError, "#{self.class.name} must implement #perform"
    end

    def llm
      @llm ||= Llm::Client.new
    end

    def create_task(input)
      AgentTask.create!(
        user: context.user,
        agent_type: self.class.agent_type,
        input: input,
        context: context.memory.to_h,
        parent_task: context.task
      )
    end

    def persist_result(task, result)
      if result.requires_approval
        task.update!(status: "awaiting_approval", output: result.data)
      elsif result.success?
        task.complete!(result.data.merge(message: result.message))
      else
        task.fail!(result.message)
      end
    end
  end
end
