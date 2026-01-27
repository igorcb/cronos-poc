class ProjectsController < ApplicationController
  before_action :require_authentication
  before_action :set_project, only: [ :edit, :update, :destroy ]
  before_action :validate_company_id_param, only: [ :projects_json ]
  skip_before_action :require_authentication, only: [:projects_json], if: :json_request?

  def index
    @projects = Project.includes(:company).order(created_at: :desc)
  end

  # JSON API for dynamic project filtering by company
  def projects_json
    @projects = if params[:company_id].present?
                  Project.where(company_id: params[:company_id]).order(:name)
    else
                  Project.all.order(:name)
    end

    render json: @projects.select(:id, :name).map { |p| { id: p.id, name: p.name } }
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
      render :new, status: :unprocessable_entity
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

  def json_request?
    request.format.json?
  end

  def validate_company_id_param
    return unless params[:company_id].present?

    unless params[:company_id].to_s.match?(/^\d+$/)
      render json: { error: "Invalid company_id parameter" }, status: :bad_request
    end
  end

  def set_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "Projeto não encontrado"
  end

  def project_params
    params.require(:project).permit(:name, :company_id)
  end
end
