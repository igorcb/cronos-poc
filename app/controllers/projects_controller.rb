class ProjectsController < ApplicationController
  before_action :require_authentication
  before_action :set_project, only: [ :edit, :update, :destroy ]
  before_action :validate_company_id_param, only: [ :projects_json ]
  # Story 9.2 — DM-008: projects_json agora exige autenticação para isolamento multi-tenant.
  # (anteriormente havia skip via `skip_before_action :require_authentication, ... if: json_request?` —
  # vazaria projetos de qualquer tenant. Removido.)

  def index
    @projects = scoped_projects.includes(:company).order(created_at: :desc)
  end

  # JSON API for dynamic project filtering by company.
  # Multi-tenant: lista apenas projetos do current_user.
  def projects_json
    base = scoped_projects
    @projects = if params[:company_id].present?
                  base.where(company_id: params[:company_id]).order(:name)
    else
                  base.order(:name)
    end

    render json: @projects.select(:id, :name).map { |p| { id: p.id, name: p.name } }
  end

  def new
    @project = scoped_projects.new
    @companies = scoped_companies.active.order(:name)
  end

  def create
    @project = scoped_projects.new(project_params)
    # Story 9.3 — DM-008 (QA #H2): captura antes do save (consistente com
    # CompaniesController e TasksController — evita race em requests paralelos).
    onboarding_active_before_save = OnboardingState.new(Current.user).active?

    if @project.save
      if onboarding_active_before_save
        redirect_to root_path, notice: t("onboarding.flashes.project_created")
      else
        redirect_to projects_path, notice: "Projeto cadastrado com sucesso"
      end
    else
      @companies = scoped_companies.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @companies = scoped_companies.active.order(:name)
  end

  def update
    if @project.update(project_params)
      redirect_to projects_path, notice: "Projeto atualizado com sucesso"
    else
      @companies = scoped_companies.active.order(:name)
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

  def validate_company_id_param
    return unless params[:company_id].present?

    unless params[:company_id].to_s.match?(/^\d+$/)
      render json: { error: "Invalid company_id parameter" }, status: :bad_request
    end
  end

  def set_project
    @project = scoped_projects.find(params[:id])
  end

  def project_params
    # NOTE: :user_id NÃO permitido — injetado server-side via scoped_projects.new.
    params.require(:project).permit(:name, :company_id)
  end
end
