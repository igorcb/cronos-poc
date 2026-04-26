class DashboardController < ApplicationController
  include DashboardCalculations

  def index
    @tasks              = monthly_tasks
    @daily_hours        = calculate_daily_hours
    @monthly_hours      = calculate_monthly_hours
    @monthly_value      = calculate_monthly_value
    @daily_task_count   = calculate_daily_task_count
    @monthly_task_count = calculate_monthly_task_count
    @daily_value        = calculate_daily_value
  end
end
