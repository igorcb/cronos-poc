class TaskItem < ApplicationRecord
  # ASSOCIAÇÕES
  belongs_to :user
  belongs_to :task

  # Multi-tenant (story 9.2 QA #5): user_id é imutável após create.
  attr_readonly :user_id

  # VALIDAÇÕES
  validates :task_id, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending completed] }
  validates :work_date, presence: true

  before_validation :set_work_date_default
  before_validation :inherit_user_from_task

  validate :end_time_after_start_time
  validate :task_must_not_be_delivered, on: [ :create, :update ]
  # Multi-tenant (story 9.2 QA #8): user_id deve coincidir com task.user_id.
  validate :user_id_matches_task_user_id, on: :create

  # Callbacks de validação para destroy
  before_destroy :prevent_destroy_if_task_delivered

  # ENUMS
  enum :status, { pending: "pending", completed: "completed" }

  # CALLBACKS
  before_save :calculate_hours_worked
  before_save :calculate_value
  after_save :update_task_status
  after_destroy :update_task_status
  after_commit :notify_totals_changed
  after_commit :broadcast_dashboard_update

  # SCOPES
  scope :by_task, ->(task_id) { where(task_id:) }
  scope :recent_first, -> { order(created_at: :desc) }

  # Expressão SQL que calcula a duração em segundos, tratando virada de meia-noite
  # (end_time < start_time → adiciona 86400 segundos = 24h)
  DURATION_SECONDS_SQL = <<~SQL.squish.freeze
    CASE WHEN end_time < start_time
      THEN EXTRACT(EPOCH FROM (end_time - start_time)) + 86400
      ELSE EXTRACT(EPOCH FROM (end_time - start_time))
    END
  SQL

  DURATION_SECONDS_SQL_PREFIXED = <<~SQL.squish.freeze
    CASE WHEN task_items.end_time < task_items.start_time
      THEN EXTRACT(EPOCH FROM (task_items.end_time - task_items.start_time)) + 86400
      ELSE EXTRACT(EPOCH FROM (task_items.end_time - task_items.start_time))
    END
  SQL

  def self.total_minutes(relation = all)
    seconds = relation.sum(DURATION_SECONDS_SQL)
    (seconds / 60).floor
  end

  private

  # Validação: duração deve ser positiva (permite virada de meia-noite)
  def end_time_after_start_time
    return unless start_time.present? && end_time.present?

    duration = end_time - start_time
    duration += 86400 if duration < 0
    errors.add(:end_time, "deve ser diferente da hora inicial") if duration == 0
  end

  # Validação: não pode modificar TaskItem de Task delivered
  def task_must_not_be_delivered
    return unless task.present?

    if task.delivered?
      errors.add(:base, "Não é possível modificar itens de tarefa já entregue")
    end
  end

  # Callback: calcula hours_worked automaticamente, tratando virada de meia-noite
  def calculate_hours_worked
    return unless start_time.present? && end_time.present?

    duration_in_seconds = end_time - start_time
    duration_in_seconds += 86400 if duration_in_seconds < 0
    self.hours_worked = (duration_in_seconds / 3600.0).round(4)
  end

  def calculate_value
    rate = task.company&.hourly_rate || 0
    self.hourly_rate = rate
    self.value = (hours_worked || 0) * rate
  end

  # Callback: atualiza status e horas da Task pai
  def update_task_status
    task&.recalculate_status!
    task&.recalculate_validated_hours
  end

  def notify_totals_changed
  end

  def broadcast_dashboard_update
    # Multi-tenant (story 9.2 — DM-008): passar user_id para o job, evitando
    # vazamento entre tenants no Turbo stream.
    DashboardBroadcastJob.perform_later(user_id)
  end

  def set_work_date_default
    self.work_date ||= Date.current
  end

  # Multi-tenant (story 9.2 — DM-008): TaskItem herda user_id da Task pai.
  # Garante isolamento mesmo quando o item é construído a partir de @task.task_items.build
  # (que não propaga user_id automaticamente).
  def inherit_user_from_task
    self.user_id ||= task&.user_id
  end

  # Multi-tenant (story 9.2 QA #8): user_id deve coincidir com task.user_id.
  # Defesa em profundidade: protege contra mass-assignment de user_id diferente da task.
  def user_id_matches_task_user_id
    return unless task.present? && user_id.present?
    return if user_id == task.user_id

    errors.add(:user_id, "deve coincidir com user_id da task")
  end

  # Callback: previne deleção se task foi delivered
  def prevent_destroy_if_task_delivered
    return unless task.present? && task.delivered?

    errors.add(:base, "Não é possível modificar itens de tarefa já entregue")
    throw(:abort)
  end
end
