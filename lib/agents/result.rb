# frozen_string_literal: true

module Agents
  class Result
    attr_reader :success, :data, :message, :delegate_to, :requires_approval

    def initialize(success:, data: {}, message: nil, delegate_to: nil, requires_approval: false)
      @success = success
      @data = data.with_indifferent_access
      @message = message
      @delegate_to = delegate_to
      @requires_approval = requires_approval
    end

    def success?
      success
    end

    def failure?
      !success
    end

    def self.ok(data = {}, message: nil)
      new(success: true, data: data, message: message)
    end

    def self.fail(message, data = {})
      new(success: false, data: data, message: message)
    end

    def self.delegate(agent_type, data = {}, message: nil)
      new(success: true, data: data, message: message, delegate_to: agent_type)
    end

    def self.approval_required(data = {}, message: nil)
      new(success: true, data: data, message: message, requires_approval: true)
    end
  end
end
