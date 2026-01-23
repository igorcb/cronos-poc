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

class Task < ApplicationRecord
  # Associações
  belongs_to :company
  belongs_to :project
  has_many :task_items, dependent: :destroy

  # Enums
  enum :status, { pending: "pending", completed: "completed", delivered: "delivered" }

  # Validações
  validates :name, presence: true
  validates :company_id, presence: true
  validates :project_id, presence: true
  validates :start_date, presence: true
  validates :estimated_hours, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed delivered] }

  # Validação customizada
  validate :project_must_belong_to_company

  # Scopes
  scope :by_status, ->(status) { where(status:) }
  scope :by_company, ->(company_id) { where(company_id:) }
  scope :by_project, ->(project_id) { where(project_id:) }

  private

  def project_must_belong_to_company
    return unless project && company

    if project.company_id != company_id
      errors.add(:project, "deve pertencer à mesma empresa")
    end
  end
end
