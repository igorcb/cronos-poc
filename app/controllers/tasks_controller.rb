class TasksController < ApplicationController
  before_action :require_authentication

  def new
    @task = Task.new
    @companies = Company.active.order(:name)
  end

  def create
    @task = Task.new(task_params)
    @task.status = 'pending'

    if @task.save
      redirect_to root_path, notice: "Tarefa criada com sucesso"
    else
      @companies = Company.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def task_params
    params.require(:task).permit(:name, :company_id, :project_id, :start_date, :estimated_hours, :notes)
  end
end
