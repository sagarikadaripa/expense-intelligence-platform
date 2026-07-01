# frozen_string_literal: true

class AuditLogger
  def self.log(user:, action:, resource: nil, metadata: {}, ip_address: nil)
    AuditLog.create!(
      user: user,
      action: action,
      resource_type: resource&.class&.name,
      resource_id: resource&.id&.to_s,
      metadata: metadata,
      ip_address: ip_address
    )
  end
end
