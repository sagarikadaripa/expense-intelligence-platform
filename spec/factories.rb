# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "user#{n}@example.com" }
    mobile_number { "+9198765432#{rand(100..999)}" }
    whatsapp_number { mobile_number }
    preferred_currency { "INR" }
    timezone { "Asia/Kolkata" }
    password { "password123" }
    monthly_budget_cents { 50_000_00 }
    onboarding_completed_at { Time.current }

    trait :with_upi do
      after(:create) do |user|
        create(:upi_id, user: user, upi_id: "test@upi", primary: true)
      end
    end
  end

  factory :upi_id do
    user
    sequence(:upi_id) { |n| "user#{n}@upi" }
    primary { false }
  end

  factory :category do
    name { "Food" }
    slug { "food" }
    system { true }
  end

  factory :transaction do
    user
    category
    amount_cents { 500_00 }
    currency { "INR" }
    payment_method { "upi" }
    source { "upi" }
    status { "completed" }
    description { "Test expense" }
    transaction_at { Time.current }
    sequence(:fingerprint) { |n| "fp-#{n}" }
  end
end
