class IdlePeriodsController < ApplicationController
  include DashboardCalculations

  before_action :require_authentication
  before_action :set_idle_period, only: [ :destroy ]

  def new
    @idle_period = Current.user.idle_periods.build(work_date: Date.current)
  end

  def create
    @idle_period = Current.user.idle_periods.build(idle_period_params)

    if @idle_period.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.action(:remove, "modal"),
            turbo_stream.replace("dashboard_daily_idle_hours", partial: "dashboard/daily_idle_hours", locals: { daily_idle_hours: calculate_daily_idle_hours }),
            turbo_stream.replace("dashboard_monthly_idle_hours", partial: "dashboard/monthly_idle_hours", locals: { monthly_idle_hours: calculate_monthly_idle_hours })
          ]
        end
        format.html { redirect_to root_path, notice: "Período sem tarefa registrado" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "modal",
            partial: "idle_periods/modal_form",
            locals: { idle_period: @idle_period }
          )
        end
        format.html { redirect_to root_path, alert: @idle_period.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    if @idle_period.destroy
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("idle_period_#{@idle_period.id}"),
            turbo_stream.replace("dashboard_daily_idle_hours", partial: "dashboard/daily_idle_hours", locals: { daily_idle_hours: calculate_daily_idle_hours }),
            turbo_stream.replace("dashboard_monthly_idle_hours", partial: "dashboard/monthly_idle_hours", locals: { monthly_idle_hours: calculate_monthly_idle_hours })
          ]
        end
        format.html { redirect_to root_path, notice: "Período sem tarefa removido" }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_content }
        format.html { redirect_to root_path, alert: "Não foi possível remover o período sem tarefa" }
      end
    end
  end

  private

  def set_idle_period
    # Scoping via Current.user garante 404 (não 403) em cross-tenant —
    # mesmo padrão de TaskItemsController#set_task_item
    @idle_period = Current.user.idle_periods.find(params[:id])
  end

  def idle_period_params
    params.require(:idle_period).permit(:start_time, :end_time, :work_date)
  end
end
