FactoryBot.define do
  factory :task_item do
    association :task
    start_time { '09:00' }
    end_time { '10:30' }
    work_date { Date.current }
    status { 'pending' }
    # user_id é herdado da task via callback before_validation (TaskItem#inherit_user_from_task).
    user { task&.user }

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
