FactoryBot.define do
  factory :idle_period do
    association :user
    start_time { "09:00" }
    end_time { "11:00" }
    work_date { Date.current }

    trait :long_duration do
      start_time { "08:00" }
      end_time { "12:00" }
    end
  end
end
