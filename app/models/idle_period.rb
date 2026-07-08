class IdlePeriod < ApplicationRecord
  belongs_to :user

  # Multi-tenant (padrão TaskItem, story 9.2 QA #5): user_id é imutável após create.
  attr_readonly :user_id

  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :work_date, presence: true

  validate :end_time_after_start_time

  before_save :calculate_hours

  scope :by_user_and_month, ->(user, date) { where(user:, work_date: date.all_month) }

  private

  def end_time_after_start_time
    return unless start_time.present? && end_time.present?

    if end_time <= start_time
      errors.add(:end_time, "deve ser posterior à hora inicial")
    end
  end

  # hours é NOT NULL no banco; depende das validações de presence de
  # start_time/end_time rodarem antes deste callback para nunca gravar nil.
  def calculate_hours
    return unless start_time.present? && end_time.present?

    duration_in_seconds = (end_time - start_time)
    self.hours = (duration_in_seconds / 3600.0).round(2)
  end
end
