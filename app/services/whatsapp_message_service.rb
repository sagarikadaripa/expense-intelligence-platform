# frozen_string_literal: true

class WhatsappMessageService
  def initialize(user)
    @user = user
    @orchestrator = Agents::Orchestrator.new(user: user)
  end

  def process!(message)
    result = @orchestrator.dispatch("whatsapp_message", { message: message })
    AuditLogger.log(user: @user, action: "whatsapp.message_processed", metadata: { message: message })
    { success: result.success?, reply: result.data[:reply] || result.message, data: result.data }
  end
end
