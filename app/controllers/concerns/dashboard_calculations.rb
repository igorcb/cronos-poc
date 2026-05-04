module DashboardCalculations
  def monthly_tasks
    Task
      .includes(:company, :project, :task_items)
      .where(start_date: Date.current.all_month)
      .order(start_date: :desc, created_at: :desc)
  end

  def calculate_daily_hours
    TaskItem.total_minutes(TaskItem.joins(:task).where(tasks: { start_date: Date.current }))
  end

  def calculate_monthly_hours
    TaskItem.total_minutes(TaskItem.joins(:task).where(tasks: { start_date: Date.current.all_month }))
  end

  def calculate_monthly_value
    Company.joins(tasks: :task_items)
           .where(tasks: { start_date: Date.current.all_month })
           .sum("EXTRACT(EPOCH FROM (task_items.end_time - task_items.start_time)) / 3600.0 * companies.hourly_rate")
  end

  def calculate_daily_task_count
    Task.joins(:task_items).where(task_items: { work_date: Date.current }).distinct.count
  end

  def calculate_monthly_task_count
    Task.joins(:task_items).where(task_items: { work_date: Date.current.all_month }).distinct.count
  end

  def calculate_daily_value
    TaskItem.joins(task: :company)
            .where(work_date: Date.current)
            .sum("EXTRACT(EPOCH FROM (task_items.end_time - task_items.start_time)) / 3600.0 * companies.hourly_rate")
  end
end
