require 'rails_helper'

RSpec.describe "Companies", type: :request do
  let!(:user) { User.create!(email: "test@example.com", password: "password123") }

  # Helper to sign in user
  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  describe "authentication requirement" do
    it "redirects to login when not authenticated" do
      get companies_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /companies" do
    before { sign_in(user) }

    context "when there are no companies" do
      it "returns success" do
        get companies_path
        expect(response).to have_http_status(:success)
      end

      it "displays empty state message" do
        get companies_path
        expect(response.body).to include("Nenhuma empresa cadastrada")
      end
    end

    context "when there are active companies" do
      let!(:company1) { create(:company, name: "Empresa A", hourly_rate: 150.00) }
      let!(:company2) { create(:company, name: "Empresa B", hourly_rate: 200.00) }
      let!(:inactive_company) { create(:company, :inactive, name: "Empresa Inativa") }

      it "displays only active companies" do
        get companies_path
        expect(response.body).to include("Empresa A")
        expect(response.body).to include("Empresa B")
        expect(response.body).not_to include("Empresa Inativa")
      end

      it "displays company hourly rate" do
        get companies_path
        expect(response.body).to include("150")
        expect(response.body).to include("200")
      end

      it "displays link to create new company" do
        get companies_path
        expect(response.body).to include("Nova Empresa")
      end
    end
  end

  describe "GET /companies/new" do
    before { sign_in(user) }

    it "returns success" do
      get new_company_path
      expect(response).to have_http_status(:success)
    end

    it "displays the company form" do
      get new_company_path
      expect(response.body).to include("Nova Empresa")
      expect(response.body).to include("Nome")
      expect(response.body).to include("Taxa")
    end
  end

  describe "POST /companies" do
    before { sign_in(user) }

    context "with valid parameters" do
      let(:valid_params) { { company: { name: "Nova Empresa", hourly_rate: 175.50 } } }

      it "creates a new company" do
        expect {
          post companies_path, params: valid_params
        }.to change(Company, :count).by(1)
      end

      it "redirects to companies index" do
        post companies_path, params: valid_params
        expect(response).to redirect_to(companies_path)
      end

      it "displays success flash message" do
        post companies_path, params: valid_params
        follow_redirect!
        expect(response.body).to include("Empresa cadastrada com sucesso")
      end

      it "creates company with correct attributes" do
        post companies_path, params: valid_params
        company = Company.last
        expect(company.name).to eq("Nova Empresa")
        expect(company.hourly_rate).to eq(175.50)
        expect(company.active).to be true
      end
    end

    context "with invalid parameters" do
      context "when name is missing" do
        let(:invalid_params) { { company: { name: "", hourly_rate: 100.00 } } }

        it "does not create a company" do
          expect {
            post companies_path, params: invalid_params
          }.not_to change(Company, :count)
        end

        it "returns unprocessable entity status" do
          post companies_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "displays validation error" do
          post companies_path, params: invalid_params
          expect(response.body).to include("Nome") # Error message about name
        end
      end

      context "when hourly_rate is missing" do
        let(:invalid_params) { { company: { name: "Test", hourly_rate: "" } } }

        it "does not create a company" do
          expect {
            post companies_path, params: invalid_params
          }.not_to change(Company, :count)
        end

        it "returns unprocessable entity status" do
          post companies_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when hourly_rate is negative" do
        let(:invalid_params) { { company: { name: "Test", hourly_rate: -50.00 } } }

        it "does not create a company" do
          expect {
            post companies_path, params: invalid_params
          }.not_to change(Company, :count)
        end

        it "returns unprocessable entity status" do
          post companies_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when hourly_rate is zero" do
        let(:invalid_params) { { company: { name: "Test", hourly_rate: 0 } } }

        it "does not create a company" do
          expect {
            post companies_path, params: invalid_params
          }.not_to change(Company, :count)
        end
      end
    end
  end
end
