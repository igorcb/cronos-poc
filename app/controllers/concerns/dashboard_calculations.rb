# Cálculos do dashboard (story 9.2 — DM-008):
# Todas as queries são escopadas a `scoped_*` (Current.user) via TenantScoped concern.
# Multi-tenant: cada user vê apenas seus próprios totais/KPIs.
module DashboardCalculations
  def monthly_tasks
    scoped_tasks
      .includes(:company, :project, :task_items)
      .left_joins(:task_items)
      .where(
        "task_items.work_date BETWEEN ? AND ? OR (task_items.id IS NULL AND tasks.start_date BETWEEN ? AND ?)",
        Date.current.beginning_of_month, Date.current.end_of_month,
        Date.current.beginning_of_month, Date.current.end_of_month
      )
      .distinct
      .order(start_date: :desc, created_at: :desc)
  end

  def calculate_daily_hours
    TaskItem.total_minutes(scoped_task_items.where(work_date: Date.current))
  end

  def calculate_monthly_hours
    TaskItem.total_minutes(scoped_task_items.where(work_date: Date.current.all_month))
  end

  def calculate_monthly_value
    scoped_companies.joins(tasks: :task_items)
           .where(task_items: { work_date: Date.current.all_month })
           .sum("(#{TaskItem::DURATION_SECONDS_SQL_PREFIXED}) / 3600.0 * companies.hourly_rate")
  end

  def calculate_daily_task_count
    scoped_tasks.where(start_date: Date.current).count
  end

  def calculate_monthly_task_count
    scoped_tasks.joins(:task_items).where(task_items: { work_date: Date.current.all_month }).distinct.count
  end

  def calculate_daily_value
    scoped_task_items.joins(task: :company)
            .where(work_date: Date.current)
            .sum("(#{TaskItem::DURATION_SECONDS_SQL_PREFIXED}) / 3600.0 * companies.hourly_rate")
  end

  def calculate_monthly_delivered_count
    monthly_delivered_task_ids.size
  end

  def calculate_monthly_delivered_hours
    scoped_tasks.where(id: monthly_delivered_task_ids).sum(:validated_hours)
  end

  def calculate_monthly_delivered_value
    scoped_tasks.where(id: monthly_delivered_task_ids)
        .joins(:company)
        .sum("tasks.validated_hours * companies.hourly_rate")
  end

  def calculate_monthly_avg_per_delivery
    count = monthly_delivered_task_ids.size
    return 0 if count.zero?

    calculate_monthly_delivered_value / count
  end

  private

  def monthly_delivered_task_ids
    @monthly_delivered_task_ids ||= scoped_tasks
      .where(status: :delivered)
      .joins(:task_items)
      .where(task_items: { work_date: Date.current.all_month })
      .distinct
      .pluck(:id)
  end
end
