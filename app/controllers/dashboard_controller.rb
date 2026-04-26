class DashboardController < ApplicationController
  def index
    @tasks = Task
      .includes(:company, :project, :task_items)
      .where(start_date: Date.current.all_month)
      .order(start_date: :desc, created_at: :desc)

    @daily_hours        = calculate_daily_hours
    @monthly_hours      = calculate_monthly_hours
    @monthly_value      = calculate_monthly_value
    @daily_task_count   = calculate_daily_task_count
    @monthly_task_count = calculate_monthly_task_count
    @daily_value        = calculate_daily_value
  end

  private

  def calculate_daily_hours
    TaskItem
      .joins(:task)
      .where(tasks: { start_date: Date.current })
      .sum(:hours_worked)
  end

  def calculate_monthly_hours
    TaskItem
      .joins(:task)
      .where(tasks: { start_date: Date.current.all_month })
      .sum(:hours_worked)
  end

  def calculate_monthly_value
    Company
      .joins(tasks: :task_items)
      .where(tasks: { start_date: Date.current.all_month })
      .sum("task_items.hours_worked * companies.hourly_rate")
  end

  def calculate_daily_task_count
    Task.joins(:task_items)
        .where(task_items: { work_date: Date.current })
        .distinct
        .count
  end

  def calculate_monthly_task_count
    Task.joins(:task_items)
        .where(task_items: { work_date: Date.current.all_month })
        .distinct
        .count
  end

  def calculate_daily_value
    TaskItem.joins(task: :company)
            .where(work_date: Date.current)
            .sum("task_items.hours_worked * companies.hourly_rate")
  end
end
