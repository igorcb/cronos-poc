FactoryBot.define do
  factory :task_item do
    association :task
    start_time { '09:00' }
    end_time { '10:30' }
    status { 'pending' }

    trait :completed do
      status { 'completed' }
    end

    trait :long_duration do
      start_time { '08:00' }
      end_time { '18:30' }
    end

    trait :short_duration do
      start_time { '14:00' }
      end_time { '14:30' }
    end
  end
end
