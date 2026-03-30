class TasksController < ApplicationController
  before_action :require_authentication

  def index
    @tasks = Task
      .includes(:company, :project, :task_items)
      .where(start_date: Date.current.all_month)
      .order(start_date: :desc, created_at: :desc)

    @daily_total = TaskItem
      .joins(:task)
      .where(tasks: { start_date: Date.current })
      .sum(:hours_worked)
  end

  def new
    @task = Task.new
    @companies = Company.active.order(:name)
  end

  def create
    @task = Task.new(task_params)
    @task.status = "pending"

    if @task.save
      redirect_to root_path, notice: "Tarefa criada com sucesso"
    else
      @companies = Company.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def task_params
    params.require(:task).permit(:name, :company_id, :project_id, :start_date, :estimated_hours_hm, :notes)
  end
end
