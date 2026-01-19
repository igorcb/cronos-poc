class ProjectsController < ApplicationController
  before_action :require_authentication

  def index
    @projects = Project.includes(:company).order(created_at: :desc)
  end

  def new
    @project = Project.new
    @companies = Company.active.order(:name)
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to projects_path, notice: "Projeto cadastrado com sucesso"
    else
      @companies = Company.active.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  private

  def project_params
    params.require(:project).permit(:name, :company_id)
  end
end
