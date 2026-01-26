class TaskItem < ApplicationRecord
  # ASSOCIAÇÕES
  belongs_to :task

  # VALIDAÇÕES
  validates :task_id, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending completed] }

  validate :end_time_after_start_time
  validate :task_must_not_be_delivered, on: [ :create, :update ]

  # Callbacks de validação para destroy
  before_destroy :prevent_destroy_if_task_delivered

  # ENUMS
  enum :status, { pending: "pending", completed: "completed" }

  # CALLBACKS
  before_save :calculate_hours_worked
  after_save :update_task_status
  after_destroy :update_task_status

  # SCOPES
  scope :by_task, ->(task_id) { where(task_id:) }
  scope :recent_first, -> { order(created_at: :desc) }

  private

  # Validação: end_time deve ser posterior à start_time
  def end_time_after_start_time
    return unless start_time.present? && end_time.present?

    if end_time <= start_time
      errors.add(:end_time, "deve ser posterior à hora inicial")
    end
  end

  # Validação: não pode modificar TaskItem de Task delivered
  def task_must_not_be_delivered
    return unless task.present?

    if task.delivered?
      errors.add(:base, "Não é possível modificar itens de tarefa já entregue")
    end
  end

  # Callback: calcula hours_worked automaticamente
  def calculate_hours_worked
    return unless start_time.present? && end_time.present?

    duration_in_seconds = (end_time - start_time)
    self.hours_worked = (duration_in_seconds / 3600.0).round(2)
  end

  # Callback: atualiza status e horas da Task pai
  def update_task_status
    task&.recalculate_status!
    task&.recalculate_validated_hours
  end

  # Callback: previne deleção se task foi delivered
  def prevent_destroy_if_task_delivered
    return unless task.present? && task.delivered?

    errors.add(:base, "Não é possível modificar itens de tarefa já entregue")
    throw(:abort)
  end
end
