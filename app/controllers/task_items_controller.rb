class TaskItemsController < ApplicationController
  before_action :require_authentication
  before_action :set_task
  before_action :set_task_item, only: [ :update, :destroy ]

  def create
    @task_item = @task.task_items.build(task_item_params)

    if @task_item.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
            turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals })
          ]
        end
        format.html { redirect_to tasks_path, notice: "Item criado com sucesso" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("task_item_errors_#{@task.id}", partial: "task_items/errors", locals: { task_item: @task_item }) }
        format.html { redirect_to tasks_path, alert: @task_item.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    if @task_item.update(task_item_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("daily_total", partial: "tasks/daily_total", locals: { daily_total: calculate_daily_total }),
            turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals })
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
          turbo_stream.replace("company_monthly_totals", partial: "tasks/company_monthly_totals", locals: { totals: calculate_company_totals })
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
    params.require(:task_item).permit(:start_time, :end_time, :status)
  end
end
