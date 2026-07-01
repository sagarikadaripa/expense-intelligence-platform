# frozen_string_literal: true

module Agents
  class NotificationAgent < BaseAgent
    protected

    def perform(input)
      user = context.user
      type = input[:notification_type] || infer_type(input)
      channel = input[:channel] || "whatsapp"

      notification = user.notifications.create!(
        notification_type: type,
        channel: channel,
        title: input[:title] || type.titleize,
        body: input[:body] || input[:message],
        payload: input.except(:notification_type, :channel, :title, :body, :message),
        scheduled_at: input[:scheduled_at],
        status: input[:scheduled_at] ? "scheduled" : "pending"
      )

      NotificationDeliveryJob.perform_later(notification.id) unless input[:scheduled_at]

      Result.ok({ notification_id: notification.id })
    end

    private

    def infer_type(input)
      return "budget_alert" if input[:budget_risk]
      return "anomaly_alert" if input[:anomaly]
      "general"
    end
  end
end
