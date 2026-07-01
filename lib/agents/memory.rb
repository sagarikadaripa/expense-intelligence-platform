# frozen_string_literal: true

module Agents
  class Memory
    def initialize(data = {})
      @data = data.with_indifferent_access
    end

    def store(key, value)
      @data[key] = value
      value
    end

    def recall(key)
      @data[key]
    end

    def to_h
      @data.deep_dup
    end
  end
end
