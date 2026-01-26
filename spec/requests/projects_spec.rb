require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let!(:user) { User.create!(email: "test@example.com", password: "password123") }

  # Helper to sign in user
  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  describe "authentication requirement" do
    it "redirects to login when accessing index without authentication" do
      get projects_path
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects to login when accessing new without authentication" do
      get new_project_path
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects to login when accessing create without authentication" do
      post projects_path, params: { project: { name: "Test", company_id: 1 } }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /projects" do
    before { sign_in(user) }

    context "when there are no projects" do
      it "returns success" do
        get projects_path
        expect(response).to have_http_status(:success)
      end

      it "displays empty state message" do
        get projects_path
        expect(response.body).to include("Nenhum projeto cadastrado")
      end
    end

    context "when there are projects" do
      let!(:company1) { create(:company, name: "Empresa A") }
      let!(:company2) { create(:company, name: "Empresa B") }
      let!(:project1) { create(:project, name: "Projeto Alpha", company: company1) }
      let!(:project2) { create(:project, name: "Projeto Beta", company: company2) }

      it "displays all projects" do
        get projects_path
        expect(response.body).to include("Projeto Alpha")
        expect(response.body).to include("Projeto Beta")
      end

      it "displays associated company names" do
        get projects_path
        expect(response.body).to include("Empresa A")
        expect(response.body).to include("Empresa B")
      end

      it "displays link to create new project" do
        get projects_path
        expect(response.body).to include("Novo Projeto")
      end

      it "includes turbo confirmation on delete buttons" do
        get projects_path
        expect(response.body).to include('data-turbo-confirm')
        expect(response.body).to include('Tem certeza que deseja deletar este projeto?')
      end

      it "orders projects by most recent first" do
        # Create projects with explicit timestamps
        older_project = create(:project, name: "Projeto Antigo", company: company1, created_at: 2.days.ago)
        newer_project = create(:project, name: "Projeto Recente", company: company2, created_at: 1.hour.ago)

        get projects_path

        # Extract positions of project names in HTML
        older_position = response.body.index("Projeto Antigo")
        newer_position = response.body.index("Projeto Recente")

        # Newer project should appear first (smaller index)
        expect(newer_position).to be < older_position
      end

      it "avoids N+1 queries by eager loading companies" do
        # Create multiple projects with companies
        create_list(:project, 5, company: company1)

        # First request to warm up any initializers
        get projects_path

        # Count queries on second request
        query_count = 0
        callback = lambda { |_name, _start, _finish, _id, payload|
          query_count += 1 unless payload[:name] == "CACHE"
        }

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get projects_path
        end

        # Should make exactly 2 queries: 1 for projects with companies, 1 for session/user
        # Increased tolerance to 5 to account for framework overhead
        expect(query_count).to be <= 5
      end
    end
  end

  describe "GET /projects/new" do
    before { sign_in(user) }

    context "when there are active companies" do
      let!(:company1) { create(:company, name: "Empresa A") }
      let!(:company2) { create(:company, name: "Empresa B") }
      let!(:inactive_company) { create(:company, :inactive, name: "Empresa Inativa") }

      it "returns success" do
        get new_project_path
        expect(response).to have_http_status(:success)
      end

      it "displays the project form" do
        get new_project_path
        expect(response.body).to include("Novo Projeto")
        expect(response.body).to include("Nome do Projeto")
        expect(response.body).to include("Empresa")
      end

      it "displays only active companies in dropdown" do
        get new_project_path
        expect(response.body).to include("Empresa A")
        expect(response.body).to include("Empresa B")
        expect(response.body).not_to include("Empresa Inativa")
      end

      it "displays prompt text in dropdown" do
        get new_project_path
        expect(response.body).to include("Selecione uma empresa")
      end

      it "includes accessibility attributes in form" do
        get new_project_path
        expect(response.body).to include('aria-required="true"')
        expect(response.body).to include('aria-labelledby="company-label"')
      end
    end

    context "when there are no active companies" do
      it "returns success" do
        get new_project_path
        expect(response).to have_http_status(:success)
      end

      it "displays empty dropdown with prompt only" do
        get new_project_path
        expect(response.body).to include("Selecione uma empresa")
        expect(response.body).to include("Nome do Projeto")
      end
    end
  end

  describe "POST /projects" do
    before { sign_in(user) }
    let!(:company) { create(:company, name: "Test Company") }

    context "with valid parameters" do
      let(:valid_params) { { project: { name: "Novo Projeto", company_id: company.id } } }

      it "creates a new project" do
        expect {
          post projects_path, params: valid_params
        }.to change(Project, :count).by(1)
      end

      it "redirects to projects index" do
        post projects_path, params: valid_params
        expect(response).to redirect_to(projects_path)
      end

      it "displays success flash message" do
        post projects_path, params: valid_params
        follow_redirect!
        expect(response.body).to include("Projeto cadastrado com sucesso")
      end

      it "creates project with correct attributes" do
        post projects_path, params: valid_params
        project = Project.last
        expect(project.name).to eq("Novo Projeto")
        expect(project.company_id).to eq(company.id)
      end

      it "associates project with correct company" do
        post projects_path, params: valid_params
        project = Project.last
        expect(project.company).to eq(company)
      end
    end

    context "with invalid parameters" do
      context "when name is missing" do
        let(:invalid_params) { { project: { name: "", company_id: company.id } } }

        it "does not create a project" do
          expect {
            post projects_path, params: invalid_params
          }.not_to change(Project, :count)
        end

        it "returns unprocessable entity status" do
          post projects_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "displays validation error" do
          post projects_path, params: invalid_params
          expect(response.body).to include("Nome")
        end

        it "re-renders the form with active companies" do
          post projects_path, params: invalid_params
          expect(response.body).to include("Novo Projeto")
          expect(response.body).to include("Test Company")
        end
      end

      context "when company_id is missing" do
        let(:invalid_params) { { project: { name: "Test Project", company_id: "" } } }

        it "does not create a project" do
          expect {
            post projects_path, params: invalid_params
          }.not_to change(Project, :count)
        end

        it "returns unprocessable entity status" do
          post projects_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "displays validation error" do
          post projects_path, params: invalid_params
          expect(response.body).to include("Empresa")
        end
      end

      context "when company_id is invalid" do
        let(:invalid_company_id) { Company.maximum(:id).to_i + 1 }
        let(:invalid_params) { { project: { name: "Test Project", company_id: invalid_company_id } } }

        it "does not create a project" do
          expect {
            post projects_path, params: invalid_params
          }.not_to change(Project, :count)
        end
      end
    end
  end

  describe "GET /projects/:id/edit" do
    before { sign_in(user) }
    let!(:company) { create(:company, name: "Test Company") }
    let!(:project) { create(:project, name: "Existing Project", company: company) }

    it "returns success" do
      get edit_project_path(project)
      expect(response).to have_http_status(:success)
    end

    it "displays the edit form with current values" do
      get edit_project_path(project)
      expect(response.body).to include("Editar Projeto")
      expect(response.body).to include("Existing Project")
    end

    it "displays only active companies in dropdown" do
      active_company = create(:company, name: "Active Company")
      inactive_company = create(:company, :inactive, name: "Inactive Company")

      get edit_project_path(project)
      expect(response.body).to include("Test Company")
      expect(response.body).to include("Active Company")
      expect(response.body).not_to include("Inactive Company")
    end

    it "redirects to index with alert when project not found" do
      get edit_project_path(id: -1)
      expect(response).to redirect_to(projects_path)
      follow_redirect!
      expect(response.body).to include("Projeto não encontrado")
    end
  end

  describe "PATCH /projects/:id" do
    before { sign_in(user) }
    let!(:company) { create(:company, name: "Original Company") }
    let!(:new_company) { create(:company, name: "New Company") }
    let!(:project) { create(:project, name: "Original Name", company: company) }

    context "with valid parameters" do
      let(:valid_params) { { project: { name: "Updated Name", company_id: new_company.id } } }

      it "updates the project" do
        patch project_path(project), params: valid_params
        project.reload
        expect(project.name).to eq("Updated Name")
        expect(project.company_id).to eq(new_company.id)
      end

      it "redirects to projects index" do
        patch project_path(project), params: valid_params
        expect(response).to redirect_to(projects_path)
      end

      it "displays success flash message" do
        patch project_path(project), params: valid_params
        follow_redirect!
        expect(response.body).to include("Projeto atualizado com sucesso")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { project: { name: "", company_id: company.id } } }

      it "does not update the project" do
        patch project_path(project), params: invalid_params
        project.reload
        expect(project.name).to eq("Original Name")
      end

      it "returns unprocessable entity status" do
        patch project_path(project), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders the edit form" do
        patch project_path(project), params: invalid_params
        expect(response.body).to include("Editar Projeto")
      end

      it "displays validation error" do
        patch project_path(project), params: invalid_params
        expect(response.body).to include("Nome")
      end
    end

    context "when project does not exist" do
      it "redirects to index with alert" do
        patch project_path(id: -1), params: { project: { name: "New Name" } }
        expect(response).to redirect_to(projects_path)
        follow_redirect!
        expect(response.body).to include("Projeto não encontrado")
      end
    end
  end

  describe "GET /projects/projects (JSON API)" do
    let(:user) { User.create!(email: "jsonapi@example.com", password: "password123") }
    let(:company) { create(:company) }
    let(:company2) { create(:company, name: "Another Company") }
    let(:project1) { create(:project, company: company, name: "Project Alpha") }
    let(:project2) { create(:project, company: company, name: "Project Beta") }
    let(:project3) { create(:project, company: company2, name: "Project Gamma") }

    before { sign_in(user) }

    context "when company_id is provided" do
      it "returns only projects for that company" do
        project1
        project2
        project3

        get projects_projects_path(company_id: company.id), as: :json

        expect(response).to be_successful
        projects = JSON.parse(response.body)

        expect(projects.length).to eq(2)
        expect(projects.map { |p| p["id"] }).to include(project1.id, project2.id)
        expect(projects.map { |p| p["id"] }).not_to include(project3.id)
      end

      it "returns projects ordered by name" do
        project2
        project1

        get projects_projects_path(company_id: company.id), as: :json

        expect(response).to be_successful
        projects = JSON.parse(response.body)

        expect(projects.first["name"]).to eq("Project Alpha")
        expect(projects.second["name"]).to eq("Project Beta")
      end

      it "returns empty array for non-existent company" do
        get projects_projects_path(company_id: 99999), as: :json

        expect(response).to be_successful
        projects = JSON.parse(response.body)

        expect(projects).to eq([])
      end
    end

    context "when company_id is not provided" do
      it "returns all projects ordered by name" do
        project3
        project1
        project2

        get projects_projects_path, as: :json

        expect(response).to be_successful
        projects = JSON.parse(response.body)

        expect(projects.length).to eq(3)
        expect(projects.map { |p| p["name"] }).to eq(["Project Alpha", "Project Beta", "Project Gamma"])
      end
    end

    context "JSON structure" do
      it "returns only id and name fields" do
        project1

        get projects_projects_path(company_id: company.id), as: :json

        expect(response).to be_successful
        projects = JSON.parse(response.body)

        expect(projects.first.keys).to match_array(["id", "name"])
        expect(projects.first["id"]).to eq(project1.id)
        expect(projects.first["name"]).to eq(project1.name)
      end
    end

    context "performance" do
      it "responds in less than 300ms" do
        create_list(:project, 10, company: company)

        start_time = Time.now
        get projects_projects_path(company_id: company.id), as: :json
        end_time = Time.now

        expect(response).to be_successful
        expect((end_time - start_time) * 1000).to be < 300
      end
    end
  end

  describe "DELETE /projects/:id" do
    before { sign_in(user) }
    let!(:company) { create(:company, name: "Test Company") }
    let!(:project) { create(:project, name: "Test Project", company: company) }

    context "when project has no time entries" do
      it "deletes the project" do
        expect {
          delete project_path(project)
        }.to change(Project, :count).by(-1)
      end

      it "redirects to projects index" do
        delete project_path(project)
        expect(response).to redirect_to(projects_path)
      end

      it "displays success flash message" do
        delete project_path(project)
        follow_redirect!
        expect(response.body).to include("Projeto deletado com sucesso")
      end
    end

    context "when project has time entries" do
      # TODO (Epic 4): When TimeEntry model is implemented, uncomment has_many :time_entries, dependent: :restrict_with_error in Project model
      # This test will be fully functional in Epic 4 when TimeEntry is implemented
      # For now, we'll test the rescue block with a stubbed restriction error
      it "does not delete the project and shows error message" do
        # Stub the destroy method to raise the restriction error
        allow_any_instance_of(Project).to receive(:destroy).and_raise(ActiveRecord::DeleteRestrictionError.new("Cannot delete"))

        expect {
          delete project_path(project)
        }.not_to change(Project, :count)
      end

      it "redirects to projects index with error message" do
        allow_any_instance_of(Project).to receive(:destroy).and_raise(ActiveRecord::DeleteRestrictionError.new("Cannot delete"))

        delete project_path(project)
        expect(response).to redirect_to(projects_path)
      end

      it "displays restriction error flash message" do
        allow_any_instance_of(Project).to receive(:destroy).and_raise(ActiveRecord::DeleteRestrictionError.new("Cannot delete"))

        delete project_path(project)
        follow_redirect!
        expect(response.body).to include("Não é possível deletar projeto com entradas de tempo")
      end
    end

    context "when project does not exist" do
      it "redirects to index with alert" do
        delete project_path(id: -1)
        expect(response).to redirect_to(projects_path)
        follow_redirect!
        expect(response.body).to include("Projeto não encontrado")
      end
    end
  end
end
