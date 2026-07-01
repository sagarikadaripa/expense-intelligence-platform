# frozen_string_literal: true

class ScheduledNotificationsJob < ApplicationJob
  queue_as :notifications

  def perform
    Notification.pending_delivery.find_each do |notification|
      NotificationDeliveryJob.perform_later(notification.id)
    end
  end
end
