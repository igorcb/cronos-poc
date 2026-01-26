# == Schema Information
#
# Table name: tasks
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  company_id      :integer          not null
#  project_id      :integer          not null
#  start_date      :date             not null
#  end_date        :date
#  status          :string           default("pending"), not null
#  delivery_date   :date
#  estimated_hours :decimal(10, 2)   not null
#  validated_hours :decimal(10, 2)
#  notes           :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_tasks_on_company_id              (company_id)
#  index_tasks_on_project_id              (project_id)
#  index_tasks_on_status                  (status)
#  index_tasks_on_company_id_and_project_id  (company_id, project_id)
#
# Foreign Keys
#
#  fk_rails_...  company_id (company_id => companies.id)
#  fk_rails_...  project_id (project_id => projects.id)
#

FactoryBot.define do
  factory :task do
    name { Faker::Lorem.sentence(word_count: 3) }
    company
    project { association :project, company: company }
    start_date { Date.today }
    end_date { 1.week.from_now.to_date }
    status { 'pending' }
    estimated_hours { Faker::Number.decimal(l_digits: 2, r_digits: 1) }
    validated_hours { nil }
    delivery_date { 2.weeks.from_now.to_date }
    notes { Faker::Lorem.paragraph(sentence_count: 2) }

    trait :pending do
      status { 'pending' }
    end

    trait :completed do
      status { 'completed' }
    end

    trait :delivered do
      status { 'delivered' }
    end

    trait :without_end_date do
      end_date { nil }
    end

    trait :without_validated_hours do
      validated_hours { nil }
    end

    trait :without_delivery_date do
      delivery_date { nil }
    end

    trait :with_notes do
      notes { "Detailed task notes with important information" }
    end
  end
end
