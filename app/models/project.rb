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

class Project < ApplicationRecord
  belongs_to :user
  belongs_to :company
  has_many :tasks, dependent: :restrict_with_error
  # TODO (Epic 4): Uncomment has_many :time_entries, dependent: :restrict_with_error
  # This will enforce referential integrity when TimeEntry model is implemented
  # has_many :time_entries, dependent: :restrict_with_error

  # Multi-tenant (story 9.2 QA #5): user_id é imutável após create.
  attr_readonly :user_id

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :company_id, presence: true,
            belongs_to_current_user: { class_name: "Company" }
end
