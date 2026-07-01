# frozen_string_literal: true

class Rack::Attack
  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  throttle("whatsapp/webhook", limit: 60, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/whatsapp/webhook"
  end

  throttle("auth/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/v1/auth")
  end
end
