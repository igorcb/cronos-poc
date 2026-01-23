# == Schema Information
#
# Table name: projects
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  company_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_projects_on_company_id  (company_id)
#

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    association :company
  end
end
