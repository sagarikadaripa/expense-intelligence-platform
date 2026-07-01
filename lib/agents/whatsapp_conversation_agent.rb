# frozen_string_literal: true

module Agents
  class WhatsappConversationAgent < BaseAgent
    protected

    def perform(input)
      user = context.user
      message = input[:message].to_s.strip
      session = find_or_create_session(user)

      if command_message?(message)
        return delegate_command(session, message)
      end

      case session.state
      when "idle"
        handle_new_expense(session, message)
      when "awaiting_category"
        handle_category_reply(session, message)
      when "awaiting_confirmation"
        handle_confirmation(session, message)
      else
        handle_new_expense(session, message)
      end
    end

    private

    def find_or_create_session(user)
      user.conversation_sessions.active.find_or_create_by!(channel: "whatsapp") do |s|
        s.state = "idle"
        s.expires_at = 1.hour.from_now
      end
    end

    def command_message?(message)
      Agents::CommandAgent::COMMAND_PATTERNS.keys.any? { |p| message.match?(p) }
    end

    def delegate_command(session, message)
      result = Orchestrator.new(user: context.user).delegate("command", { message: message }, context: context)
      log_message(session, "user", message)
      log_message(session, "assistant", result.message)
      result
    end

    def handle_new_expense(session, message)
      parse_result = Orchestrator.new(user: context.user).delegate("parsing", { message: message }, context: context)
      parsed = parse_result.data

      log_message(session, "user", message)

      unless parsed[:complete]
        session.update!(state: "awaiting_category", context: parsed)
        reply = "Got ₹#{parsed[:amount_cents] / 100.0}. What category is this expense?"
        log_message(session, "assistant", reply)
        return Result.ok({ reply: reply, session_state: session.state })
      end

      create_expense_from_parsed(session, parsed)
    end

    def handle_category_reply(session, message)
      parsed = session.context.merge("category_hint" => message.downcase, "complete" => true)
      create_expense_from_parsed(session, parsed.with_indifferent_access)
    end

    def handle_confirmation(session, message)
      if message.upcase == "CONFIRM"
        action = session.context["pending_action"]
        session.reset!
        Result.ok({ action: action, confirmed: true }, message: "Done!")
      else
        session.reset!
        Result.ok({ cancelled: true }, message: "Cancelled.")
      end
    end

    def create_expense_from_parsed(session, parsed)
      category = Category.for_user(context.user).find_by(slug: parsed[:category_hint]) ||
                 Category.for_user(context.user).find_by(slug: "other")
      merchant = Merchant.find_or_create_by_name!(parsed[:merchant_name]) if parsed[:merchant_name].present?

      transaction = context.user.transactions.create!(
        amount_cents: parsed[:amount_cents],
        currency: context.user.preferred_currency,
        category: category,
        merchant: merchant,
        payment_method: parsed[:payment_method] || "cash",
        source: "whatsapp",
        status: "completed",
        description: parsed[:description],
        transaction_at: Time.current
      )

      session.reset!
      reply = "✅ Recorded #{transaction.amount.formatted} under #{category.name}."
      log_message(session, "assistant", reply)
      Result.ok({ transaction_id: transaction.id, reply: reply })
    end

    def log_message(session, role, content)
      session.conversation_messages.create!(role: role, content: content)
    end
  end
end
