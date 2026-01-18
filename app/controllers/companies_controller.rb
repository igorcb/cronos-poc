class CompaniesController < ApplicationController
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
      render :new, status: :unprocessable_entity
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :hourly_rate)
  end
end
