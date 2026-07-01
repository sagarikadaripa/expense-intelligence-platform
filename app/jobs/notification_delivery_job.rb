# frozen_string_literal: true

class NotificationDeliveryJob < ApplicationJob
  queue_as :notifications

  def perform(notification_id)
    notification = Notification.find(notification_id)
    Whatsapp::Client.new.send_message(
      to: notification.user.whatsapp_number,
      body: notification.body
    )
    notification.update!(status: "sent", sent_at: Time.current)
  rescue StandardError => e
    notification.update!(status: "failed", payload: notification.payload.merge(error: e.message))
    raise
  end
end
