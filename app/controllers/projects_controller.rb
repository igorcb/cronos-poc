class ProjectsController < ApplicationController
  before_action :require_authentication
  before_action :set_project, only: [ :edit, :update, :destroy ]

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

  def edit
    @companies = Company.active.order(:name)
  end

  def update
    if @project.update(project_params)
      redirect_to projects_path, notice: "Projeto atualizado com sucesso"
    else
      @companies = Company.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Projeto deletado com sucesso"
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to projects_path, alert: "Não é possível deletar projeto com entradas de tempo"
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :company_id)
  end
end
