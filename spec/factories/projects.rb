# == Schema Information
#
# Table name: projects
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  company_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_projects_on_company_id  (company_id)
#  index_projects_on_user_id     (user_id)
#

# Multi-tenant (story 9.2 — DM-008):
# Project compartilha user com a Company associada.
# Estratégia: se caller passa `user:`, usar para criar/atribuir Company;
# senão, deixar a association cuidar.
FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    company
    user { company&.user }
  end
end
