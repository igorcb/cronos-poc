# == Schema Information
#
# Table name: companies
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  hourly_rate :decimal(10, 2)   not null
#  active      :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_companies_on_active  (active)
#

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
