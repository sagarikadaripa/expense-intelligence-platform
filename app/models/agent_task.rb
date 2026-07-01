# frozen_string_literal: true

class AgentTask < ApplicationRecord
  STATUSES = %w[pending running completed failed awaiting_approval].freeze

  belongs_to :user, optional: true
  belongs_to :parent_task, class_name: "AgentTask", optional: true
  has_many :child_tasks, class_name: "AgentTask", foreign_key: :parent_task_id

  validates :agent_type, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def complete!(output)
    update!(status: "completed", output: output)
  end

  def fail!(message)
    update!(status: "failed", error_message: message)
  end
end
