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
  # Validações
  validates :name, presence: true
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

  # Override destroy para prevenir deleção acidental
  def destroy
    if respond_to?(:time_entries) && time_entries.exists?
      errors.add(:base, "Não é possível deletar empresa com entradas de tempo associadas. Use deactivate! para desativar.")
      throw(:abort)
    else
      super
    end
  end
end
