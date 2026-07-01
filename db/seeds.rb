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
  user = User.find_or_initialize_by(email: "sagarika@expense.local")
  user.assign_attributes(
    name: "Sagarika",
    mobile_number: "+917091362239",
    whatsapp_number: "+917091362239",
    password: "password123",
    preferred_currency: "INR",
    timezone: "Asia/Kolkata",
    whatsapp_verified: true,
    onboarding_completed_at: Time.current
  )
  user.save!

  demo_descriptions = ["Swiggy order", "Coffee", "Uber ride", "Amazon electronics"]
  user.transactions.where(description: demo_descriptions).destroy_all

  puts ""
  puts "Your account is ready (import real data via dashboard):"
  puts "  Email:      sagarika@expense.local"
  puts "  Password:   password123"
  puts "  WhatsApp:   +917091362239"
  puts ""
end
