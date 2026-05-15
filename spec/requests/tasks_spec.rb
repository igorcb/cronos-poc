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

      it "includes project selector and form-validation Stimulus controllers" do
        get new_task_path
        # Story 1.10: form-validation adicionado junto com project-selector
        expect(response.body).to include('project-selector form-validation')
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
            code: "10001",
            name: "Nova Tarefa",
            company_id: company.id,
            project_id: project.id,
            start_date: Date.today,
            estimated_hours_hm: "08:00",
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

      it "redirects to tasks path" do
        post tasks_path, params: valid_params
        expect(response).to redirect_to(tasks_path)
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
          expect(response.body).to include("erros encontrados")
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
              estimated_hours_hm: "08:00"
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

  describe "navbar navigation link" do
    context "when authenticated" do
      before { sign_in(user) }

      it "exibe o link 'Tarefas' no menu desktop (AC1, AC3, AC4)" do
        get tasks_path
        expect(response.body).to include('href="/tasks"')
        expect(response.body).to include("Tarefas")
        expect(response.body).to include("text-gray-300 hover:text-blue-400 px-3 py-2 rounded-md text-sm font-medium")
      end

      it "exibe o link 'Tarefas' no menu mobile (AC2, AC3, AC4)" do
        get tasks_path
        expect(response.body).to include('href="/tasks"')
        expect(response.body).to match(/href="\/tasks"[^>]*>Tarefas</)
        expect(response.body).to include("block text-gray-300 hover:text-blue-400 hover:bg-gray-700 px-3 py-2 rounded-md text-base font-medium")
      end
    end

    context "when not authenticated" do
      it "nao exibe a navbar com link 'Tarefas' — redireciona para login (AC5)" do
        get tasks_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /tasks — campo code (AC3, AC6)" do
    before { sign_in(user) }

    let!(:company) { create(:company, name: "Code Company") }
    let!(:project) { create(:project, company: company, name: "Code Project") }

    def base_params(overrides = {})
      {
        task: {
          name: "Tarefa com Código",
          company_id: company.id,
          project_id: project.id,
          start_date: Date.today,
          estimated_hours_hm: "02:00"
        }.merge(overrides)
      }
    end

    context "with valid numeric code" do
      it "creates the task with the given code" do
        post tasks_path, params: base_params(code: "14335")
        expect(Task.last.code).to eq("14335")
      end

      it "redirects to tasks path" do
        post tasks_path, params: base_params(code: "14335")
        expect(response).to redirect_to(tasks_path)
      end
    end

    context "without code (required field)" do
      it "does not create the task" do
        expect {
          post tasks_path, params: base_params(code: "")
        }.not_to change(Task, :count)
      end

      it "returns unprocessable entity" do
        post tasks_path, params: base_params(code: "")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with invalid (non-numeric) code" do
      it "does not create the task" do
        expect {
          post tasks_path, params: base_params(code: "ABC")
        }.not_to change(Task, :count)
      end

      it "returns unprocessable entity" do
        post tasks_path, params: base_params(code: "ABC")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with duplicate code+name combination" do
      before { create(:task, code: "999", name: "Tarefa com Código", company: company, project: project) }

      it "does not create the task" do
        expect {
          post tasks_path, params: base_params(code: "999")
        }.not_to change(Task, :count)
      end

      it "returns unprocessable entity" do
        post tasks_path, params: base_params(code: "999")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /tasks/new — exibe campo Código (AC3)" do
    before { sign_in(user) }

    let!(:company) { create(:company) }

    it "displays the Código field" do
      get new_task_path
      expect(response.body).to include("Código")
      expect(response.body).to include("Ex: 14335")
    end
  end

  describe "GET /tasks — coluna Valor (AC4 story 5.21)" do
    let(:company) { create(:company, hourly_rate: 100) }
    let(:project) { create(:project, company: company) }

    before { sign_in(user) }

    it "exibe R$0,00 para task sem lançamentos" do
      create(:task, company: company, project: project, start_date: Date.current)
      get tasks_path
      expect(response.body).to include("R$0,00")
    end

    it "exibe valor acumulado para task não entregue com lançamentos" do
      task = create(:task, company: company, project: project, start_date: Date.current)
      create(:task_item, task: task, start_time: "09:00", end_time: "10:00")
      get tasks_path
      expect(response.body).to include("R$100,00")
    end

    it "exibe delivered_value (snapshot) para task entregue" do
      task = create(:task, company: company, project: project, start_date: Date.current)
      create(:task_item, task: task, start_time: "09:00", end_time: "10:00")
      task.update!(status: "completed")
      task.update!(status: "delivered")
      get tasks_path
      expect(response.body).to include("R$100,00")
    end
  end

  describe "GET /tasks/:id/edit — Story 4.16 fix combobox Projeto disabled" do
    before { sign_in(user) }

    let!(:company) { create(:company, name: "Empresa Edit") }
    let!(:project) { create(:project, company: company, name: "Projeto Edit") }
    let!(:other_project) { create(:project, company: company, name: "Outro Projeto") }
    let!(:task) { create(:task, company: company, project: project, start_date: Date.current) }

    it "AC1: renderiza combobox Projeto SEM atributo disabled" do
      get edit_task_path(task)
      doc = Nokogiri::HTML(response.body)
      select_node = doc.at_css("select#task_project_id")
      expect(select_node).to be_present
      expect(select_node["disabled"]).to be_nil
    end

    it "AC2: combobox Projeto vem populado com projetos da empresa do task" do
      get edit_task_path(task)
      expect(response.body).to include("Projeto Edit")
      expect(response.body).to include("Outro Projeto")
    end

    it "AC3: combobox Projeto vem com projeto atual selecionado" do
      get edit_task_path(task)
      doc = Nokogiri::HTML(response.body)
      selected = doc.at_css("select#task_project_id option[selected]")
      expect(selected).to be_present
      expect(selected["value"]).to eq(project.id.to_s)
    end
  end

  describe "PATCH /tasks/:id — Story 4.16 fix combobox Projeto" do
    before { sign_in(user) }

    let!(:company) { create(:company, name: "Empresa PATCH") }
    let!(:project) { create(:project, company: company, name: "Projeto PATCH") }
    let!(:task) { create(:task, company: company, project: project, name: "Nome Antigo", start_date: Date.current) }

    it "AC4: editar apenas o nome (sem mexer em empresa/projeto) salva com sucesso" do
      patch task_path(task), params: {
        task: {
          name: "Nome Novo",
          company_id: task.company_id,
          project_id: task.project_id,
          code: task.code,
          estimated_hours_hm: "02:00",
          start_date: task.start_date.to_s
        }
      }
      expect(response).to redirect_to(tasks_path)
      expect(task.reload.name).to eq("Nome Novo")
    end
  end

  describe "DELETE /tasks/:id" do
    let!(:task) { create(:task) }

    before { sign_in(user) }

    it "destroys the task and redirects" do
      expect {
        delete task_path(task)
      }.to change(Task, :count).by(-1)
      expect(response).to redirect_to(tasks_path)
    end

    it "redirects with alert when destroy fails" do
      allow_any_instance_of(Task).to receive(:destroy).and_return(false)
      delete task_path(task)
      expect(response).to redirect_to(tasks_path)
      expect(flash[:alert]).to match(/Não foi possível remover/)
    end
  end
end
