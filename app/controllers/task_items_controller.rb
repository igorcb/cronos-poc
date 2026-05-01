class TaskItemsController < ApplicationController
  include DashboardCalculations

  before_action :require_authentication
  before_action :set_task
  before_action :set_task_item, only: [ :update, :destroy ]

  def new
    @task_item = @task.task_items.build(work_date: Date.current)
    @task_items = @task.task_items.recent_first
  end

  def create
    @task_item = @task.task_items.build(task_item_params)

    if @task_item.save
      respond_to do |format|
        format.turbo_stream do
          @task_items = @task.task_items.recent_first
          daily = calculate_daily_total
          totals = calculate_company_totals
          monthly_hours = calculate_monthly_hours
          monthly_value = calculate_monthly_value
          render turbo_stream: [
            turbo_stream.update("task-items-list-#{@task.id}", partial: "task_items/list", locals: { task_items: @task_items }),
            turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: daily }),
            turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: totals }),
            turbo_stream.replace("dashboard_daily_hours", partial: "dashboard/daily_hours", locals: { daily_hours: daily }),
            turbo_stream.replace("dashboard_monthly_hours", partial: "dashboard/monthly_hours", locals: { monthly_hours: monthly_hours }),
            turbo_stream.replace("dashboard_monthly_value", partial: "dashboard/monthly_value", locals: { monthly_value: monthly_value })
          ]
        end
        format.html { redirect_to tasks_path, notice: "Item criado com sucesso" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          @task_items = @task.task_items.recent_first
          render turbo_stream: turbo_stream.replace(
            "modal",
            partial: "task_items/modal_form",
            locals: { task: @task, task_item: @task_item, task_items: @task_items }
          )
        end
        format.html { redirect_to tasks_path, alert: @task_item.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    if @task_item.update(task_item_params)
      respond_to do |format|
        format.turbo_stream do
          @task_items = @task.task_items.recent_first
          render turbo_stream: [
            turbo_stream.update("task-items-list-#{@task.id}", partial: "task_items/list", locals: { task_items: @task_items }),
            turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
            turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals }),
            turbo_stream.replace("dashboard_daily_hours", partial: "dashboard/daily_hours", locals: { daily_hours: calculate_daily_hours }),
            turbo_stream.replace("dashboard_monthly_hours", partial: "dashboard/monthly_hours", locals: { monthly_hours: calculate_monthly_hours }),
            turbo_stream.replace("dashboard_monthly_value", partial: "dashboard/monthly_value", locals: { monthly_value: calculate_monthly_value }),
            turbo_stream.replace("dashboard_daily_value", partial: "dashboard/daily_value", locals: { daily_value: calculate_daily_value }),
            turbo_stream.replace("dashboard_daily_task_count", partial: "dashboard/daily_task_count", locals: { daily_task_count: calculate_daily_task_count }),
            turbo_stream.replace("dashboard_monthly_task_count", partial: "dashboard/monthly_task_count", locals: { monthly_task_count: calculate_monthly_task_count }),
            turbo_stream.update("tasks-list", partial: "dashboard/tasks_list", locals: { tasks: monthly_tasks })
          ]
        end
        format.html { redirect_to tasks_path, notice: "Item atualizado com sucesso" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("task_item_errors_#{@task.id}", partial: "task_items/errors", locals: { task_item: @task_item }) }
        format.html { redirect_to tasks_path, alert: @task_item.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    @task_item.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
          turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals }),
          turbo_stream.replace("dashboard_daily_hours", partial: "dashboard/daily_hours", locals: { daily_hours: calculate_daily_hours }),
          turbo_stream.replace("dashboard_monthly_hours", partial: "dashboard/monthly_hours", locals: { monthly_hours: calculate_monthly_hours }),
          turbo_stream.replace("dashboard_monthly_value", partial: "dashboard/monthly_value", locals: { monthly_value: calculate_monthly_value }),
          turbo_stream.replace("dashboard_daily_value", partial: "dashboard/daily_value", locals: { daily_value: calculate_daily_value }),
          turbo_stream.replace("dashboard_daily_task_count", partial: "dashboard/daily_task_count", locals: { daily_task_count: calculate_daily_task_count }),
          turbo_stream.replace("dashboard_monthly_task_count", partial: "dashboard/monthly_task_count", locals: { monthly_task_count: calculate_monthly_task_count }),
          turbo_stream.update("tasks-list", partial: "dashboard/tasks_list", locals: { tasks: monthly_tasks })
        ]
      end
      format.html { redirect_to tasks_path, notice: "Item removido com sucesso" }
    end
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end

  def set_task_item
    @task_item = @task.task_items.find(params[:id])
  end

  def calculate_daily_total
    TaskItem
      .joins(:task)
      .where(tasks: { start_date: Date.current })
      .sum(:hours_worked)
  end

  def calculate_company_totals
    Company
      .joins(tasks: :task_items)
      .where(tasks: { start_date: Date.current.all_month })
      .group("companies.id", "companies.name", "companies.hourly_rate")
      .select(
        "companies.id",
        "companies.name",
        "companies.hourly_rate",
        "SUM(task_items.hours_worked) as total_hours"
      )
      .order("companies.name")
  end

  def task_item_params
    params.require(:task_item).permit(:start_time, :end_time, :work_date, :status)
  end
end
