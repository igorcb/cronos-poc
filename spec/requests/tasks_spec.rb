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

  describe "Story 4.17 — Form edit completo (todos os dados)" do
    before { sign_in(user) }

    describe "GET /tasks/:id/edit" do
      context "task pending — campos editáveis (AC1, AC5.1)" do
        let!(:task) { create(:task, :pending, code: "12345", name: "Tarefa Demo", notes: "obs ABC") }

        it "exibe todos os novos campos editáveis (AC1.1, AC1.2, AC1.3)" do
          get edit_task_path(task)
          expect(response).to have_http_status(:success)
          # campo end_date (AC1.2) — verificação específica via name
          expect(response.body).to include('name="task[end_date]"')
          # campo status select (AC1.3)
          expect(response.body).to include('name="task[status]"')
          expect(response.body).to match(/<option[^>]*value="pending"/)
          expect(response.body).to match(/<option[^>]*value="completed"/)
          expect(response.body).to match(/<option[^>]*value="delivered"/)
        end

        it "tabs iniciam com Dados Principais ativa e demais ocultas (Story 4.17 tabs)" do
          get edit_task_path(task)
          expect(response.body).to match(/id="tab-dados"[^>]*aria-selected="true"/)
          expect(response.body).to match(/id="tab-horas"[^>]*aria-selected="false"/)
          expect(response.body).to match(/id="tab-financeiro"[^>]*aria-selected="false"/)
          expect(response.body).to match(/id="panel-horas"[^>]*hidden/)
          expect(response.body).to match(/id="panel-financeiro"[^>]*hidden/)
        end

        it "exibe bloco Horas read-only (AC2.1)" do
          get edit_task_path(task)
          expect(response.body).to include("Horas Validadas")
          expect(response.body).to include('data-testid="edit-validated-hours"')
          expect(response.body).to include("Total de Lançamentos")
          expect(response.body).to include('data-testid="edit-task-items-count"')
        end

        it "exibe bloco Financeiro read-only (AC2.2)" do
          get edit_task_path(task)
          expect(response.body).to include("Tarifa Atual da Empresa")
          expect(response.body).to include('data-testid="edit-company-hourly-rate"')
          expect(response.body).to include("Valor Acumulado")
          expect(response.body).to include('data-testid="edit-total-value"')
        end

        it "exibe timestamps no rodapé (AC2.3)" do
          get edit_task_path(task)
          expect(response.body).to include('data-testid="edit-created-at"')
          expect(response.body).to include('data-testid="edit-updated-at"')
          expect(response.body).to match(/Criado em:\s*\d{2}\/\d{2}\/\d{4}/)
        end

        it "status NÃO está disabled para task pending (AC3.1 negativo)" do
          get edit_task_path(task)
          # extrai o trecho do select de status
          status_select = response.body[/name="task\[status\]"[^>]*>/]
          expect(status_select).not_to include("disabled")
        end
      end

      context "task delivered — campos disabled (AC3)" do
        let!(:task) do
          t = create(:task, :pending, code: "99999", name: "Para Entregar")
          t.update!(status: "delivered")
          t
        end

        it "exibe status disabled com hint (AC3.1)" do
          get edit_task_path(task)
          # o select está disabled
          expect(response.body).to match(/<select[^>]*disabled[^>]*name="task\[status\]"/m)
          # hint informa que tarefa entregue não tem status editável
          expect(response.body).to include("Tarefa entregue")
          expect(response.body).to include("Reabrir tarefa")
        end

        it "exibe delivery_date e tarifa snapshot (AC3.2)" do
          get edit_task_path(task)
          expect(response.body).to include('data-testid="edit-delivery-date"')
          # hourly_rate/delivered_value foram snapshotados no callback
          expect(response.body).to include('data-testid="edit-snapshot-hourly-rate"')
        end
      end
    end

    describe "PATCH /tasks/:id" do
      let!(:task) { create(:task, :pending) }

      it "atualiza status para completed (AC5.2)" do
        patch task_path(task), params: { task: { status: "completed" } }
        expect(task.reload.status).to eq("completed")
      end

      it "atualiza end_date e redireciona (AC5.2)" do
        new_date = 2.weeks.from_now.to_date
        patch task_path(task), params: { task: { end_date: new_date.to_s } }
        expect(response).to redirect_to(tasks_path)
        expect(task.reload.end_date).to eq(new_date)
      end

      it "ao re-renderizar form com erros, painéis Horas/Financeiro ficam visíveis (M2)" do
        patch task_path(task), params: { task: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).not_to match(/id="panel-horas"[^>]*hidden/)
        expect(response.body).not_to match(/id="panel-financeiro"[^>]*hidden/)
      end

      context "task delivered" do
        let!(:delivered_task) do
          t = create(:task, :pending)
          t.update!(status: "delivered")
          t
        end

        it "ignora alteração de status em task delivered (AC5.3)" do
          patch task_path(delivered_task), params: {
            task: { status: "pending", name: "Novo Nome" }
          }
          delivered_task.reload
          expect(delivered_task.status).to eq("delivered")  # bloqueado
          expect(delivered_task.name).to eq("Novo Nome")    # demais campos passam (AC3.3)
        end
      end
    end
  end

  describe "Story 4.18 — Reabrir tarefa entregue" do
    before { sign_in(user) }

    let(:company) { create(:company, hourly_rate: 100) }
    let(:project) { create(:project, company: company) }
    let!(:task) do
      t = create(:task, :pending, company: company, project: project, estimated_hours_hm: "01:00")
      create(:task_item, task: t, start_time: "09:00", end_time: "10:00")
      t.update!(status: :delivered)
      t
    end

    describe "link Reabrir em /tasks/:id/edit" do
      it "exibe link quando task delivered (AC1.1)" do
        get edit_task_path(task)
        expect(response.body).to include("Reabrir tarefa")
        expect(response.body).to include(reopen_modal_task_path(task))
      end

      it "NÃO exibe link quando task pending" do
        task.update!(status: :pending, delivery_date: nil)
        get edit_task_path(task)
        expect(response.body).not_to include(reopen_modal_task_path(task))
      end
    end

    describe "GET /tasks/:id/reopen_modal" do
      it "renderiza modal de confirmação (AC2.1, AC2.2)" do
        get reopen_modal_task_path(task)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Tem certeza que quer reabrir a tarefa?")
        expect(response.body).to include("Confirmar reabertura")
        expect(response.body).to include("Cancelar")
      end
    end

    describe "PATCH /tasks/:id/reopen" do
      it "reverte delivered → completed, limpa snapshot (AC3.1, AC3.2, AC3.3)" do
        patch reopen_task_path(task)
        task.reload
        expect(task.status).to eq("completed")
        expect(task.delivery_date).to be_nil
        expect(task.delivered_value).to be_nil
        expect(task.hourly_rate).to be_nil
      end

      it "redireciona para edit_task_path com flash de sucesso (AC4.1, AC3.5)" do
        patch reopen_task_path(task)
        expect(response).to redirect_to(edit_task_path(task))
        expect(flash[:notice]).to match(/reaberta com sucesso/i)
      end

      it "responde turbo_stream com KPIs e task row (AC5.1)" do
        patch reopen_task_path(task), as: :turbo_stream
        expect(response.body).to include("task_row_#{task.id}")
        expect(response.body).to include("kpi-entregas-mes")
        expect(response.body).to include("kpi-horas-entregues")
        expect(response.body).to include("kpi-valor-entregue")
        expect(response.body).to include("kpi-media-por-entrega")
        expect(response.body).to include("kpi-media-por-entrega-inline")
      end

      it "retorna alert quando task NÃO está delivered" do
        task.update!(status: :pending, delivery_date: nil)
        patch reopen_task_path(task)
        expect(response).to redirect_to(edit_task_path(task))
        expect(flash[:alert]).to match(/Apenas tarefas entregues/)
      end

      it "retorna 422 turbo_stream quando task NÃO está delivered" do
        task.update!(status: :pending, delivery_date: nil)
        patch reopen_task_path(task), as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
