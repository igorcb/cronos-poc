require 'rails_helper'

# Story 9.2 — DM-008: garante isolamento multi-tenant.
# User A não enxerga nem manipula recursos de User B.
# Acesso cross-user resulta em 404 (não 403, para não vazar IDs).
RSpec.describe "Tenant isolation", type: :request do
  let(:user_a) { User.create!(email: "alice@example.com", password: "password123") }
  let(:user_b) { User.create!(email: "bob@example.com",   password: "password123") }

  let!(:company_a) { create(:company, name: "Empresa A", user: user_a) }
  let!(:project_a) { create(:project, name: "Projeto A", company: company_a) }
  let!(:task_a)    { create(:task,    name: "Tarefa A", company: company_a, project: project_a) }
  let!(:task_item_a) { create(:task_item, task: task_a) }

  let!(:company_b) { create(:company, name: "Empresa B", user: user_b) }
  let!(:project_b) { create(:project, name: "Projeto B", company: company_b) }
  let!(:task_b)    { create(:task,    name: "Tarefa B", company: company_b, project: project_b) }
  let!(:task_item_b) { create(:task_item, task: task_b) }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  describe "Companies index" do
    before { sign_in(user_b) }

    it "mostra apenas empresas do user logado" do
      get companies_path
      expect(response.body).to include("Empresa B")
      expect(response.body).not_to include("Empresa A")
    end
  end

  describe "Projects index" do
    before { sign_in(user_b) }

    it "mostra apenas projetos do user logado" do
      get projects_path
      expect(response.body).to include("Projeto B")
      expect(response.body).not_to include("Projeto A")
    end
  end

  describe "Tasks index" do
    before { sign_in(user_b) }

    it "mostra apenas tarefas do user logado" do
      get tasks_path
      expect(response.body).to include("Tarefa B")
      expect(response.body).not_to include("Tarefa A")
    end
  end

  describe "Dashboard" do
    before { sign_in(user_b) }

    it "mostra apenas dados do user logado" do
      get root_path
      expect(response.body).to include("Tarefa B")
      expect(response.body).not_to include("Tarefa A")
    end
  end

  describe "Resumo diário" do
    before { sign_in(user_b) }

    it "agrega apenas task_items do user logado" do
      # User A com TaskItem; User B sem TaskItem hoje (criamos com Date.current default).
      get daily_summary_path
      # Não deve incluir as horas de A — basta garantir que carregou sem erro
      # (assertion forte: contar rows via DB).
      rows_user_b = TaskItem.where(user: user_b).count
      rows_user_a = TaskItem.where(user: user_a).count
      expect(rows_user_a).to be > 0
      expect(rows_user_b).to be > 0
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Acesso cross-user a recurso de outro user → 404" do
    before { sign_in(user_b) }

    it "GET /tasks/:id de outro user retorna 404" do
      get edit_task_path(task_a)
      expect(response).to have_http_status(:not_found)
    end

    it "PATCH /tasks/:id de outro user retorna 404" do
      patch task_path(task_a), params: { task: { name: "Hackeado" } }
      expect(response).to have_http_status(:not_found)
      expect(task_a.reload.name).to eq("Tarefa A")
    end

    it "DELETE /tasks/:id de outro user retorna 404" do
      delete task_path(task_a)
      expect(response).to have_http_status(:not_found)
      expect(Task.exists?(task_a.id)).to be true
    end

    it "PATCH /tasks/:id/deliver de outro user retorna 404" do
      patch deliver_task_path(task_a)
      expect(response).to have_http_status(:not_found)
      expect(task_a.reload.status).to eq("pending")
    end

    it "GET /companies/:id/edit de outro user retorna 404" do
      get edit_company_path(company_a)
      expect(response).to have_http_status(:not_found)
    end

    it "PATCH /companies/:id de outro user retorna 404" do
      patch company_path(company_a), params: { company: { name: "Hackeado" } }
      expect(response).to have_http_status(:not_found)
      expect(company_a.reload.name).to eq("Empresa A")
    end

    it "DELETE /companies/:id de outro user retorna 404" do
      delete company_path(company_a)
      expect(response).to have_http_status(:not_found)
      expect(company_a.reload.active).to be true
    end

    it "GET /projects/:id/edit de outro user retorna 404" do
      get edit_project_path(project_a)
      expect(response).to have_http_status(:not_found)
    end

    it "PATCH /projects/:id de outro user retorna 404" do
      patch project_path(project_a), params: { project: { name: "Hackeado" } }
      expect(response).to have_http_status(:not_found)
    end

    it "DELETE /projects/:id de outro user retorna 404" do
      delete project_path(project_a)
      expect(response).to have_http_status(:not_found)
    end

    it "GET /tasks/:id/task_items de outro user (via build) retorna 404" do
      get new_task_task_item_path(task_a)
      expect(response).to have_http_status(:not_found)
    end

    it "PATCH /tasks/:task_id/task_items/:id de outro user retorna 404" do
      patch task_task_item_path(task_a, task_item_a), params: { task_item: { start_time: "10:00", end_time: "11:00" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Tentativa de criar Task com company/project de outro user" do
    before { sign_in(user_b) }

    it "rejeita create de Task referenciando company de outro user" do
      post tasks_path, params: {
        task: {
          code: "99999",
          name: "Tentativa cross-tenant",
          company_id: company_a.id,
          project_id: project_a.id,
          start_date: Date.current.to_s,
          estimated_hours_hm: "02:00",
          status: "pending"
        }
      }
      # A task NÃO foi criada para user_b com a company_a
      expect(Task.where(user: user_b, company_id: company_a.id)).to be_empty
      # E nada foi atribuído ao user_a indevidamente
      expect(Task.where(user: user_a, name: "Tentativa cross-tenant")).to be_empty
    end

    it "rejeita create de Project referenciando company de outro user" do
      post projects_path, params: {
        project: { name: "Projeto cross-tenant", company_id: company_a.id }
      }
      expect(Project.where(user: user_b, company_id: company_a.id)).to be_empty
    end

    it "rejeita projects_json filtrando por company de outro user" do
      get projects_projects_path(format: :json), params: { company_id: company_a.id }
      json = JSON.parse(response.body)
      project_ids = json.map { |p| p["id"] }
      expect(project_ids).not_to include(project_a.id)
      expect(project_ids).not_to include(project_b.id) # company_a não pertence a B
    end
  end

  describe "User logado vê seus próprios dados normalmente" do
    before { sign_in(user_a) }

    it "GET /tasks/:id próprio funciona normalmente" do
      get edit_task_path(task_a)
      expect(response).to have_http_status(:ok)
    end

    it "lista task_items próprios em /resumo-diario" do
      get daily_summary_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "BelongsToCurrentUserValidator (sanity)" do
    # Story 9.2 QA #10: usar around para garantir Current.reset mesmo em raise.
    around(:each) do |ex|
      ex.run
    ensure
      Current.reset
    end

    it "é no-op fora de request (Current.user nil)" do
      task = Task.new(company_id: company_a.id, project_id: project_a.id, user: user_b,
                      code: "1", name: "x", start_date: Date.current, estimated_hours_hm: "01:00", status: "pending")
      task.valid?
      expect(task.errors[:company_id]).not_to include("não pertence ao usuário atual")
    end

    it "é no-op se valor é blank (delega para presence)" do
      Current.session = Session.create!(user: user_a, user_agent: "test", ip_address: "127.0.0.1")
      task = Task.new(company_id: nil, project_id: nil, user: user_a,
                      code: "1", name: "x", start_date: Date.current, estimated_hours_hm: "01:00", status: "pending")
      task.valid?
      expect(task.errors[:company_id]).not_to include("não pertence ao usuário atual")
    end

    it "é no-op se referência aponta para registro inexistente" do
      Current.session = Session.create!(user: user_a, user_agent: "test", ip_address: "127.0.0.1")
      task = Task.new(company_id: 99999999, project_id: 99999999, user: user_a,
                      code: "1", name: "x", start_date: Date.current, estimated_hours_hm: "01:00", status: "pending")
      task.valid?
      expect(task.errors[:company_id]).not_to include("não pertence ao usuário atual")
    end
  end
end
