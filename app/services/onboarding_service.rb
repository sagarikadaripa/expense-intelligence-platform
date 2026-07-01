# frozen_string_literal: true

class OnboardingService
  def register!(params)
    user = User.new(params)
    user.password = params[:password] || SecureRandom.hex(16)

    ActiveRecord::Base.transaction do
      user.save!
      seed_default_categories!(user)
      user.update!(onboarding_completed_at: Time.current)
      Agents::Orchestrator.new(user: user).dispatch("schedule_notifications", {})
    end

    user
  end

  private

  def seed_default_categories!(user)
    %w[food groceries transport shopping rent utilities entertainment health_fitness education other].each do |slug|
      Category.find_or_create_by!(user: nil, slug: slug, system: true) do |c|
        c.name = Category.system_category_name(slug)
      end
    end
  end
end
