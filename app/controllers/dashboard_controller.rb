class DashboardController < ApplicationController
  include DashboardCalculations

  def index
    # Story 9.3 — DM-008: cache de OnboardingState evita N+1 (QA #C1) —
    # 1 instância × 3 EXISTS no pior caso, reusada por view gate e partial.
    @onboarding_state = OnboardingState.new(Current.user)

    return if @onboarding_state.active?

    @tasks              = monthly_tasks
    @daily_hours        = calculate_daily_hours
    @monthly_hours      = calculate_monthly_hours
    @monthly_value      = calculate_monthly_value
    @daily_task_count   = calculate_daily_task_count
    @monthly_task_count = calculate_monthly_task_count
    @daily_value        = calculate_daily_value
    @daily_idle_hours   = calculate_daily_idle_hours
    @monthly_idle_hours = calculate_monthly_idle_hours

    @monthly_delivered_count = calculate_monthly_delivered_count
    @monthly_delivered_hours = calculate_monthly_delivered_hours
    @monthly_delivered_value = calculate_monthly_delivered_value
    @monthly_avg_per_delivery = calculate_monthly_avg_per_delivery
  end
end
