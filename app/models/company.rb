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

class Company < ApplicationRecord
  # Associações
  has_many :projects, dependent: :restrict_with_error
  has_many :tasks, dependent: :restrict_with_error

  # Validações
  validates :name, presence: true, uniqueness: true
  validates :hourly_rate, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Soft delete
  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  # Prevent hard delete if time_entries exist
  before_destroy :prevent_destroy_if_has_time_entries, prepend: true

  private

  def prevent_destroy_if_has_time_entries
    return true unless defined?(TimeEntry) && respond_to?(:time_entries)

    if time_entries.exists?
      errors.add(:base, "Não é possível deletar empresa com entradas de tempo associadas. Use deactivate! para desativar.")
      throw :abort
    end
  end
end
