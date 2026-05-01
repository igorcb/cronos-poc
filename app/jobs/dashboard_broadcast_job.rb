class DashboardBroadcastJob < ApplicationJob
  queue_as :default

  include DashboardCalculations

  def perform
    Turbo::StreamsChannel.broadcast_render_to(
      "dashboard",
      partial: "dashboard/broadcast_streams",
      locals: {
        daily_hours:        calculate_daily_hours,
        monthly_hours:      calculate_monthly_hours,
        monthly_value:      calculate_monthly_value,
        daily_value:        calculate_daily_value,
        daily_task_count:   calculate_daily_task_count,
        monthly_task_count: calculate_monthly_task_count,
        tasks:              monthly_tasks
      }
    )
  end
end
