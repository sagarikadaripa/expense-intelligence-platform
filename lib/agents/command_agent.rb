# frozen_string_literal: true

module Agents
  class CommandAgent < BaseAgent
    COMMAND_PATTERNS = {
      /spent\s+today/i => :today_summary,
      /this\s+month/i => :month_summary,
      /remaining\s+budget/i => :remaining_budget,
      /how\s+much.*food/i => :category_spend,
      /delete\s+last/i => :delete_last,
      /edit\s+last/i => :edit_last
    }.freeze

    protected

    def perform(input)
      message = input[:message].to_s
      command = detect_command(message)

      case command
      when :today_summary
        Result.ok(summary_for(:today), message: format_summary("today"))
      when :month_summary
        Result.ok(summary_for(:month), message: format_summary("this month"))
      when :remaining_budget
        Result.ok(budget_status, message: budget_message)
      when :category_spend
        slug = extract_category(message) || "food"
        Result.ok(category_summary(slug), message: category_message(slug))
      when :delete_last
        Result.ok({ action: "delete_last" }, message: "I'll delete your last expense. Reply CONFIRM to proceed.")
      when :edit_last
        Result.ok({ action: "edit_last" }, message: "Send the updated expense like '500 groceries'.")
      else
        Result.fail("Unknown command")
      end
    end

    private

    def detect_command(message)
      COMMAND_PATTERNS.each { |pattern, cmd| return cmd if message.match?(pattern) }
      nil
    end

    def summary_for(period)
      range = period == :today ? Time.zone.today.all_day : Time.zone.today.beginning_of_month..Time.zone.now
      txns = context.user.transactions.expenses.in_period(range)
      { total_cents: txns.sum(:amount_cents), count: txns.count, period: period.to_s }
    end

    def format_summary(period)
      data = summary_for(period == "today" ? :today : :month)
      "You spent #{MoneyValue.new(data[:total_cents], context.user.preferred_currency).formatted} #{period} across #{data[:count]} transactions."
    end

    def budget_status
      budget = context.user.monthly_budget_cents
      spent = context.user.transactions.expenses.in_period(Time.zone.today.beginning_of_month..Time.zone.now).sum(:amount_cents)
      { budget_cents: budget, spent_cents: spent, remaining_cents: budget.to_i - spent }
    end

    def budget_message
      data = budget_status
      remaining = MoneyValue.new([data[:remaining_cents], 0].max, context.user.preferred_currency).formatted
      "Remaining budget this month: #{remaining}"
    end

    def category_summary(slug)
      range = Time.zone.today.beginning_of_month..Time.zone.now
      txns = context.user.transactions.expenses.by_category(slug).in_period(range)
      { slug: slug, total_cents: txns.sum(:amount_cents), count: txns.count }
    end

    def category_message(slug)
      data = category_summary(slug)
      MoneyValue.new(data[:total_cents], context.user.preferred_currency).formatted +
        " on #{slug} this month (#{data[:count]} transactions)"
    end

    def extract_category(message)
      Category.for_user(context.user).pluck(:slug).find { |slug| message.downcase.include?(slug) }
    end
  end
end
