class CompaniesController < ApplicationController
  before_action :set_company, only: [ :edit, :update, :destroy ]

  def index
    @companies = scoped_companies.active.order(created_at: :desc)
  end

  def new
    @company = scoped_companies.new
  end

  def create
    @company = scoped_companies.new(company_params)
    # Story 9.3 — DM-008 (QA #H2): capturar antes do save evita race e mantém
    # decisão determinística mesmo em requests paralelos.
    onboarding_active_before_save = OnboardingState.new(Current.user).active?

    if @company.save
      if onboarding_active_before_save
        redirect_to new_project_path, notice: t("onboarding.flashes.company_created")
      else
        redirect_to companies_path, notice: "Empresa cadastrada com sucesso"
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    # @company já definido pelo before_action
  end

  def update
    if @company.update(company_params)
      redirect_to companies_path, notice: "Empresa atualizada com sucesso"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @company.deactivate!
    redirect_to companies_path, notice: "Empresa desativada com sucesso"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to companies_path, alert: "Erro ao desativar empresa: #{e.message}"
  end

  private

  def set_company
    @company = scoped_companies.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :hourly_rate)
    # NOTE: :active NÃO está permitido - apenas via deactivate!/activate!
    # NOTE: :user_id NÃO está permitido — sempre injetado server-side via Current.user.
  end
end
