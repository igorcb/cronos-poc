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
          expect(response).to have_http_status(:unprocessable_content)
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
          expect(response).to have_http_status(:unprocessable_content)
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
          expect(response).to have_http_status(:unprocessable_content)
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

  describe "GET /companies/:id/edit" do
    before { sign_in(user) }
    let!(:company) { create(:company, name: "Test Company", hourly_rate: 150.00) }

    it "returns success" do
      get edit_company_path(company)
      expect(response).to have_http_status(:success)
    end

    it "displays the edit form with company data" do
      get edit_company_path(company)
      expect(response.body).to include("Editar Empresa")
      expect(response.body).to include("Test Company")
      expect(response.body).to include("150")
    end

    it "does not display active field" do
      get edit_company_path(company)
      expect(response.body).not_to include('name="company[active]"')
    end
  end

  describe "PATCH /companies/:id" do
    before { sign_in(user) }
    let!(:company) { create(:company, name: "Old Name", hourly_rate: 100.00) }

    context "with valid parameters" do
      let(:valid_params) { { company: { name: "Updated Name", hourly_rate: 250.00 } } }

      it "updates the company" do
        patch company_path(company), params: valid_params
        company.reload
        expect(company.name).to eq("Updated Name")
        expect(company.hourly_rate).to eq(250.00)
      end

      it "redirects to companies index" do
        patch company_path(company), params: valid_params
        expect(response).to redirect_to(companies_path)
      end

      it "displays success flash message" do
        patch company_path(company), params: valid_params
        follow_redirect!
        expect(response.body).to include("Empresa atualizada com sucesso")
      end

      it "does not change active status even if sent" do
        patch company_path(company), params: { company: { name: "Updated", hourly_rate: 200, active: false } }
        company.reload
        expect(company.active).to be true
      end
    end

    context "with invalid parameters" do
      context "when name is blank" do
        let(:invalid_params) { { company: { name: "", hourly_rate: 150.00 } } }

        it "does not update the company" do
          patch company_path(company), params: invalid_params
          company.reload
          expect(company.name).to eq("Old Name")
        end

        it "returns unprocessable entity status" do
          patch company_path(company), params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "displays validation errors" do
          patch company_path(company), params: invalid_params
          expect(response.body).to include("Nome")
        end
      end

      context "when hourly_rate is negative" do
        let(:invalid_params) { { company: { name: "Test", hourly_rate: -50.00 } } }

        it "does not update the company" do
          patch company_path(company), params: invalid_params
          company.reload
          expect(company.hourly_rate).to eq(100.00)
        end

        it "returns unprocessable entity status" do
          patch company_path(company), params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "DELETE /companies/:id" do
    before { sign_in(user) }
    let!(:company) { create(:company, name: "Company to Deactivate", hourly_rate: 150.00) }

    context "when deactivating a company" do
      it "calls deactivate! on the company" do
        expect_any_instance_of(Company).to receive(:deactivate!).and_call_original
        delete company_path(company)
      end

      it "changes the company active status to false" do
        delete company_path(company)
        company.reload
        expect(company.active).to be false
      end

      it "does not delete the company from database" do
        expect {
          delete company_path(company)
        }.not_to change(Company.unscoped, :count)
      end

      it "removes company from Company.active scope" do
        delete company_path(company)
        expect(Company.active).not_to include(company)
      end

      it "keeps company in Company.all" do
        delete company_path(company)
        company.reload
        expect(Company.unscoped.find_by(id: company.id)).to eq(company)
      end

      it "redirects to companies index" do
        delete company_path(company)
        expect(response).to redirect_to(companies_path)
      end

      it "displays success flash message" do
        delete company_path(company)
        follow_redirect!
        expect(response.body).to include("Empresa desativada com sucesso")
      end
    end

    context "when deactivation fails" do
      before do
        allow_any_instance_of(Company).to receive(:deactivate!).and_raise(ActiveRecord::RecordInvalid.new(company))
      end

      it "redirects to companies index" do
        delete company_path(company)
        expect(response).to redirect_to(companies_path)
      end

      it "displays error flash message" do
        delete company_path(company)
        follow_redirect!
        expect(response.body).to include("Erro ao desativar empresa")
      end

      it "does not change company active status" do
        delete company_path(company)
        company.reload
        expect(company.active).to be true
      end
    end
  end
end
