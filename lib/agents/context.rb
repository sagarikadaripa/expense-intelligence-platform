# frozen_string_literal: true

module Agents
  class Context
    attr_reader :user, :task, :memory, :metadata

    def initialize(user: nil, task: nil, memory: nil, metadata: {})
      @user = user
      @task = task
      @memory = memory || Memory.new
      @metadata = metadata.with_indifferent_access
    end

    def with(**attrs)
      self.class.new(
        user: attrs.fetch(:user, user),
        task: attrs.fetch(:task, task),
        memory: attrs.fetch(:memory, memory),
        metadata: metadata.merge(attrs.fetch(:metadata, {}))
      )
    end

    def store(key, value)
      memory.store(key, value)
    end

    def recall(key)
      memory.recall(key)
    end
  end
end
