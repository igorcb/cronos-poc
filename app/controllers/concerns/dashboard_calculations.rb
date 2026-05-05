module DashboardCalculations
  def monthly_tasks
    Task
      .includes(:company, :project, :task_items)
      .joins(:task_items)
      .where(task_items: { work_date: Date.current.all_month })
      .distinct
      .order(start_date: :desc, created_at: :desc)
  end

  def calculate_daily_hours
    TaskItem.total_minutes(TaskItem.where(work_date: Date.current))
  end

  def calculate_monthly_hours
    TaskItem.total_minutes(TaskItem.where(work_date: Date.current.all_month))
  end

  def calculate_monthly_value
    Company.joins(tasks: :task_items)
           .where(task_items: { work_date: Date.current.all_month })
           .sum("(#{TaskItem::DURATION_SECONDS_SQL_PREFIXED}) / 3600.0 * companies.hourly_rate")
  end

  def calculate_daily_task_count
    Task.where(start_date: Date.current).count
  end

  def calculate_monthly_task_count
    Task.where(start_date: Date.current.all_month).count
  end

  def calculate_daily_value
    TaskItem.joins(task: :company)
            .where(work_date: Date.current)
            .sum("(#{TaskItem::DURATION_SECONDS_SQL_PREFIXED}) / 3600.0 * companies.hourly_rate")
  end
end
