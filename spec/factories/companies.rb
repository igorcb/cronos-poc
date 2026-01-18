FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    hourly_rate { 100.00 }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :high_rate do
      hourly_rate { 500.00 }
    end

    trait :low_rate do
      hourly_rate { 50.00 }
    end
  end
end
