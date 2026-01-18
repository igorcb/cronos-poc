class CompaniesController < ApplicationController
  before_action :set_company, only: [ :edit, :update, :destroy ]

  def index
    @companies = Company.active.order(created_at: :desc)
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      redirect_to companies_path, notice: "Empresa cadastrada com sucesso"
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
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :hourly_rate)
    # NOTE: :active NÃO está permitido - apenas via deactivate!/activate!
  end
end
