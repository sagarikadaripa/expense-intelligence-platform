# frozen_string_literal: true

%w[
  food groceries transport shopping rent utilities
  entertainment health_fitness education other
].each do |slug|
  Category.find_or_create_by!(slug: slug, system: true, user_id: nil) do |c|
    c.name = Category.system_category_name(slug)
  end
end

if Rails.env.development?
  user = User.find_or_initialize_by(email: "demo@example.com")
  user.assign_attributes(
    name: "Demo User",
    mobile_number: "+919999999999",
    whatsapp_number: "+919999999999",
    password: "changeme123",
    preferred_currency: "INR",
    timezone: "Asia/Kolkata",
    whatsapp_verified: true,
    onboarding_completed_at: Time.current
  )
  user.save!

  demo_descriptions = ["Swiggy order", "Coffee", "Uber ride", "Amazon electronics"]
  user.transactions.where(description: demo_descriptions).destroy_all

  puts ""
  puts "Demo account ready (local development only):"
  puts "  Email:    demo@example.com"
  puts "  Password: changeme123"
  puts ""
end
