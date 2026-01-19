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

class Project < ApplicationRecord
  belongs_to :company
  # Note: TimeEntry association will be uncommented in Epic 4
  # When TimeEntry is implemented, uncomment this line:
  # has_many :time_entries, dependent: :restrict_with_error

  validates :name, presence: true
  validates :company_id, presence: true
end
