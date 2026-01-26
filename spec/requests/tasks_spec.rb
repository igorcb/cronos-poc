require "rails_helper"

RSpec.describe "Tasks", type: :request do
  let(:user) { User.create!(email: "tasks@example.com", password: "password123") }

  # Helper to sign in user
  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  describe "authentication requirement" do
    it "redirects to login when accessing new without authentication" do
      get new_task_path
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects to login when accessing create without authentication" do
      post tasks_path, params: { task: { name: "Test" } }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /tasks/new" do
    before { sign_in(user) }

    context "when there are active companies" do
      let!(:company1) { create(:company, name: "Empresa A") }
      let!(:company2) { create(:company, name: "Empresa B") }
      let!(:inactive_company) { create(:company, :inactive, name: "Empresa Inativa") }

      it "returns success" do
        get new_task_path
        expect(response).to have_http_status(:success)
      end

      it "displays the task form" do
        get new_task_path
        expect(response.body).to include("Nova Tarefa")
        expect(response.body).to include("Nome da Tarefa")
        expect(response.body).to include("Empresa")
        expect(response.body).to include("Projeto")
      end

      it "displays only active companies in dropdown" do
        get new_task_path
        expect(response.body).to include("Empresa A")
        expect(response.body).to include("Empresa B")
        expect(response.body).not_to include("Empresa Inativa")
      end

      it "includes project selector Stimulus controller" do
        get new_task_path
        expect(response.body).to include('data-controller="project-selector"')
      end
    end
  end

  describe "POST /tasks" do
    before { sign_in(user) }

    let!(:company) { create(:company, name: "Test Company") }
    let!(:project) { create(:project, company: company, name: "Test Project") }

    context "with valid parameters" do
      let(:valid_params) do
        {
          task: {
            name: "Nova Tarefa",
            company_id: company.id,
            project_id: project.id,
            start_date: Date.today,
            estimated_hours: 8.0,
            notes: "Observações"
          }
        }
      end

      it "creates a new task" do
        expect {
          post tasks_path, params: valid_params
        }.to change(Task, :count).by(1)
      end

      it "sets status to pending" do
        post tasks_path, params: valid_params
        expect(Task.last.status).to eq("pending")
      end

      it "redirects to root path" do
        post tasks_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it "displays success flash message" do
        post tasks_path, params: valid_params
        follow_redirect!
        expect(response.body).to include("Tarefa criada com sucesso")
      end
    end

    context "with invalid parameters" do
      context "when required fields are missing" do
        let(:invalid_params) { { task: { name: "" } } }

        it "does not create a task" do
          expect {
            post tasks_path, params: invalid_params
          }.not_to change(Task, :count)
        end

        it "returns unprocessable entity status" do
          post tasks_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "displays validation errors" do
          post tasks_path, params: invalid_params
          expect(response.body).to include("erros impedem")
        end
      end

      context "when project does not belong to company" do
        let(:other_company) { create(:company, name: "Other Company") }
        let(:other_project) { create(:project, company: other_company, name: "Other Project") }

        let(:invalid_params) do
          {
            task: {
              name: "Nova Tarefa",
              company_id: company.id,
              project_id: other_project.id,
              start_date: Date.today,
              estimated_hours: 8.0
            }
          }
        end

        it "does not create a task" do
          expect {
            post tasks_path, params: invalid_params
          }.not_to change(Task, :count)
        end

        it "returns unprocessable entity status" do
          post tasks_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end
end
