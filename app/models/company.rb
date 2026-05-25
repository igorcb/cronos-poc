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
#  user_id     :integer          not null
#
# Indexes
#
#  index_companies_on_active              (active)
#  index_companies_on_user_id             (user_id)
#  index_companies_on_user_id_and_active  (user_id,active)
#

class Company < ApplicationRecord
  # Associações
  belongs_to :user
  has_many :projects, dependent: :restrict_with_error
  has_many :tasks, dependent: :restrict_with_error

  # Multi-tenant (story 9.2 QA #5): user_id é imutável após create.
  # attr_readonly em Rails 8 levanta ReadonlyAttributeError em qualquer tentativa
  # de set, bloqueando mass-assignment via console/admin futura.
  attr_readonly :user_id

  # Validações
  # Story 9.2 — DM-008: nome é único por user (não mais global), pois usuários
  # diferentes podem ter clientes com o mesmo nome.
  validates :name, presence: true, uniqueness: { scope: :user_id }
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

end
