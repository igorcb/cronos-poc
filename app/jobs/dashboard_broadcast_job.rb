class DashboardBroadcastJob < ApplicationJob
  queue_as :default

  include TenantScoped
  include DashboardCalculations

  # Multi-tenant (story 9.2 — DM-008 + QA #2, #3, #16, #21):
  # - Broadcast em stream assinado por user (`[user, :dashboard]`), não em string previsível.
  # - Usa `Current.user_override` em vez de sintetizar Session fantasma — sem pollution
  #   no DB nem audit log estranho.
  # - `Current.reset` no ensure garante que SolidQueue (que reusa threads) não vaza tenant
  #   para o próximo job.
  def perform(user_id = nil)
    user = user_id ? User.find_by(id: user_id) : nil

    Current.user_override = user
    if user
      Turbo::StreamsChannel.broadcast_render_to(
        [ user, :dashboard ],
        partial: "dashboard/broadcast_streams",
        locals: build_locals(user)
      )
    else
      # Path legado (chamada sem user_id) — broadcast no stream genérico com zeros.
      Turbo::StreamsChannel.broadcast_render_to(
        "dashboard",
        partial: "dashboard/broadcast_streams",
        locals: zero_locals
      )
    end
  ensure
    Current.reset
  end

  private

  def build_locals(_user)
    {
      daily_hours:        calculate_daily_hours,
      monthly_hours:      calculate_monthly_hours,
      monthly_value:      calculate_monthly_value,
      daily_value:        calculate_daily_value,
      daily_task_count:   calculate_daily_task_count,
      monthly_task_count: calculate_monthly_task_count,
      daily_idle_hours:   calculate_daily_idle_hours,
      monthly_idle_hours: calculate_monthly_idle_hours,
      tasks:              monthly_tasks
    }
  end

  def zero_locals
    {
      daily_hours: 0, monthly_hours: 0, monthly_value: 0, daily_value: 0,
      daily_task_count: 0, monthly_task_count: 0,
      daily_idle_hours: 0, monthly_idle_hours: 0,
      tasks: Task.none
    }
  end
end
