# frozen_string_literal: true

module Llm
  class Client
    def chat(prompt:, system: nil, json: false)
      provider.chat(prompt: prompt, system: system, json: json)
    end

    private

    def provider
      @provider ||= build_provider
    end

    def build_provider
      case ENV.fetch("LLM_PROVIDER", "mock")
      when "openai"
        Providers::Openai.new
      else
        Providers::Mock.new
      end
    end
  end
end
