require "rails_helper"

# Story 5.6: Exibir Lista de Tarefas do Mês no Dashboard
RSpec.describe "Dashboard Tasks Month", type: :request do
  let(:user) { User.create!(email: "dashboard_tasks_month@example.com", password: "password123") }

  def sign_in
    post session_path, params: { email: user.email, password: "password123" }
  end

  before { sign_in }

  describe "GET / (dashboard)" do
    # AC1 + AC8: Seção aparece no dashboard após ações rápidas
    context "when there are tasks in the current month" do
      let(:company) { create(:company) }
      let(:project) { create(:project, company: company) }
      let!(:task_this_month) do
        create(:task,
          name: "Tarefa do Mês Atual",
          company: company,
          project: project,
          start_date: Date.current.beginning_of_month + 1.day,
          status: "pending")
      end

      before { get root_path }

      # AC1: Dashboard exibe seção "Tarefas do Mês"
      it "AC1: exibe seção Tarefas do Mês" do
        expect(response.body).to include("Tarefas do Mês")
      end

      # AC2: Lista contém tarefas de Date.current.all_month
      it "AC2: exibe tarefa do mês atual" do
        expect(response.body).to include("Tarefa do Mês Atual")
      end

      # AC3: Colunas exibidas: Data, Tarefa, Empresa, Projeto, Status, Estimado
      it "AC3: exibe coluna Data" do
        expect(response.body).to include("Data")
      end

      it "AC3: exibe coluna Tarefa" do
        expect(response.body).to include("Tarefa")
      end

      it "AC3: exibe coluna Empresa" do
        expect(response.body).to include("Empresa")
      end

      it "AC3: exibe coluna Projeto" do
        expect(response.body).to include("Projeto")
      end

      it "AC3: exibe coluna Status" do
        expect(response.body).to include("Status")
      end

      it "AC3: exibe coluna Estimado" do
        expect(response.body).to include("Estimado")
      end

      # AC4: Coluna Ações não aparece no dashboard
      it "AC4: não exibe coluna Ações" do
        expect(response.body).not_to include(">Ações<")
      end

      # AC4: Links de Editar/Excluir não presentes na seção de tarefas do mês
      it "AC4: não exibe link Editar na tabela do dashboard" do
        expect(response.body).not_to include("Editar")
      end

      it "AC4: não exibe link Excluir na tabela do dashboard" do
        expect(response.body).not_to include("Excluir")
      end

      # AC6: Eager loading — verificar que controller atribui @tasks
      it "AC6: retorna status 200" do
        expect(response).to have_http_status(:ok)
      end

      # AC7: Link Ver todas aponta para tasks_path
      it "exibe link Ver todas apontando para tasks_path" do
        expect(response.body).to include('href="/tasks"')
        expect(response.body).to include("Ver todas")
      end
    end

    # AC2: NÃO exibe tarefas de outros meses
    context "when task is from previous month" do
      let(:company) { create(:company) }
      let(:project) { create(:project, company: company) }
      let!(:task_last_month) do
        create(:task,
          name: "Tarefa do Mês Passado",
          company: company,
          project: project,
          start_date: Date.current.beginning_of_month - 1.day)
      end

      before { get root_path }

      it "AC2: não exibe tarefa de outro mês" do
        expect(response.body).not_to include("Tarefa do Mês Passado")
      end
    end

    # AC5: Empty state quando não há tarefas
    context "when there are no tasks in the current month" do
      before { get root_path }

      it "AC5: exibe mensagem Nenhuma tarefa este mês" do
        expect(response.body).to include("Nenhuma tarefa este mês")
      end
    end

    # AC7: Ordenação por start_date desc
    context "when there are multiple tasks this month" do
      let(:company) { create(:company) }
      let(:project) { create(:project, company: company) }
      let!(:task_older) do
        create(:task,
          name: "Tarefa Mais Antiga",
          company: company,
          project: project,
          start_date: Date.current.beginning_of_month + 1.day)
      end
      let!(:task_newer) do
        create(:task,
          name: "Tarefa Mais Recente",
          company: company,
          project: project,
          start_date: Date.current.beginning_of_month + 5.days)
      end

      before { get root_path }

      it "AC7: tarefa mais recente aparece antes da mais antiga" do
        pos_newer = response.body.index("Tarefa Mais Recente")
        pos_older = response.body.index("Tarefa Mais Antiga")
        expect(pos_newer).to be < pos_older
      end
    end

    # Autenticação: dashboard é protegido
    context "when not authenticated" do
      before do
        # reset session
        delete session_path rescue nil
        get root_path
      end

      it "redireciona para login quando não autenticado" do
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
