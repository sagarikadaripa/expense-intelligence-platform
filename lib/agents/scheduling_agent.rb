# frozen_string_literal: true

module Agents
  class SchedulingAgent < BaseAgent
    SCHEDULES = {
      "daily_summary" => { hour: 21, minute: 0 },
      "weekly_report" => { wday: 0, hour: 9, minute: 0 },
      "monthly_report" => { day: 1, hour: 9, minute: 0 }
    }.freeze

    protected

    def perform(input)
      user = context.user
      scheduled = []

      SCHEDULES.each do |type, config|
        next_at = next_occurrence(config)
        notification = user.notifications.find_or_initialize_by(
          notification_type: type,
          status: "scheduled",
          channel: "whatsapp"
        )
        notification.scheduled_at = next_at
        notification.body = "#{type.humanize} scheduled"
        notification.save!
        scheduled << { type: type, at: next_at }
      end

      Result.ok({ scheduled: scheduled })
    end

    private

    def next_occurrence(config)
      now = Time.zone.now
      if config[:wday]
        days_ahead = (config[:wday] - now.wday) % 7
        days_ahead = 7 if days_ahead.zero? && now.hour >= config[:hour]
        (now + days_ahead.days).change(hour: config[:hour], min: config[:minute])
      elsif config[:day]
        target = now.change(day: config[:day], hour: config[:hour], min: config[:minute])
        target += 1.month if target <= now
        target
      else
        target = now.change(hour: config[:hour], min: config[:minute])
        target += 1.day if target <= now
        target
      end
    end
  end
end
