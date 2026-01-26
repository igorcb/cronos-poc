class TasksController < ApplicationController
  before_action :require_authentication
  before_action :set_companies, only: [:new, :create]

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)
    @task.status = :pending

    if @task.save
      redirect_to root_path, notice: "Tarefa criada com sucesso"
    else
      render :new, status: :unprocessable_content
    end
  end

  def projects
    @projects = if params[:company_id].present?
                  Project.where(company_id: params[:company_id])
                         .order(:name)
                         .select(:id, :name)
                else
                  Project.none
                end

    render json: @projects.as_json(only: [:id, :name])
  end

  private

  def set_companies
    @companies = Company.active.order(:name)
  end

  def task_params
    params.require(:task).permit(:name, :company_id, :project_id, :start_date, :estimated_hours, :notes)
  end
end
