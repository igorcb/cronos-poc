require "rails_helper"

# Story 5.8: Modal Nova Tarefa no Dashboard
RSpec.describe "Dashboard Modal Nova Tarefa", type: :request do
  let(:user) { User.create!(email: "modal_task@example.com", password: "password123") }
  let(:company) { Company.create!(name: "Empresa Modal", hourly_rate: 100, active: true) }
  let(:project) { Project.create!(name: "Projeto Modal", company: company) }

  def sign_in
    post session_path, params: { email: user.email, password: "password123" }
  end

  before { sign_in }

  # AC1: Link do ícone + aponta para new_task_path com data-turbo-frame="modal"
  describe "GET / (dashboard)" do
    it "AC1: ícone + tem data-turbo-frame=modal no link" do
      get root_path
      expect(response.body).to include('data-turbo-frame="modal"')
    end

    it "AC1: turbo-frame#modal está presente no layout" do
      get root_path
      expect(response.body).to include('<turbo-frame id="modal">')
    end

    it "AC1: lista de tarefas tem id=tasks-list no tbody" do
      get root_path
      expect(response.body).to include('id="tasks-list"')
    end
  end

  # AC2: Formulário do modal com todos os campos
  describe "GET /tasks/new com header Turbo-Frame: modal" do
    before do
      get new_task_path, headers: { "Turbo-Frame" => "modal" }
    end

    it "AC2: retorna status 200" do
      expect(response).to have_http_status(:ok)
    end

    it "AC2: contém turbo-frame#modal na resposta" do
      expect(response.body).to include('id="modal"')
    end

    it "AC2: exibe overlay com bg-black/50" do
      expect(response.body).to include("bg-black/50")
    end

    it "AC2: exibe título Nova Tarefa" do
      expect(response.body).to include("Nova Tarefa")
    end

    it "AC2: contém campo empresa" do
      expect(response.body).to include("company_id")
    end

    it "AC2: contém campo projeto" do
      expect(response.body).to include("project_id")
    end

    it "AC2: contém campo código" do
      expect(response.body).to include("task[code]")
    end

    it "AC2: contém campo nome" do
      expect(response.body).to include("task[name]")
    end

    it "AC2: contém campo data de início" do
      expect(response.body).to include("task[start_date]")
    end

    it "AC2: contém campo horas estimadas" do
      expect(response.body).to include("task[estimated_hours_hm]")
    end

    it "AC2: contém campo status" do
      expect(response.body).to include("task[status]")
    end

    it "AC2: contém campo notas" do
      expect(response.body).to include("task[notes]")
    end

    it "AC5: botão Cancelar com data-action modal#close" do
      expect(response.body).to include('data-action="click->modal#close"')
    end

    it "AC6: fundo do modal com bg-gray-800" do
      expect(response.body).to include("bg-gray-800")
    end
  end

  # AC3: Criar tarefa via modal retorna Turbo Stream
  describe "POST /tasks com header Turbo-Frame: modal" do
    let(:valid_params) do
      {
        task: {
          code: "99001",
          name: "Tarefa via Modal",
          company_id: company.id,
          project_id: project.id,
          start_date: Date.today,
          estimated_hours_hm: "02:00",
          status: "pending",
          notes: ""
        }
      }
    end

    it "AC3: cria tarefa com sucesso" do
      expect {
        post tasks_path, params: valid_params, headers: { "Turbo-Frame" => "modal" }
      }.to change(Task, :count).by(1)
    end

    it "AC3: responde com turbo-stream para fechar modal" do
      post tasks_path, params: valid_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('target="modal"')
    end

    it "AC3: responde com turbo-stream para adicionar linha na lista" do
      post tasks_path, params: valid_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.body).to include('target="tasks-list"')
    end

    it "AC3: responde com turbo-stream para atualizar horas do dia" do
      post tasks_path, params: valid_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.body).to include('target="dashboard_daily_hours"')
    end

    it "AC3: responde com turbo-stream para atualizar horas do mês" do
      post tasks_path, params: valid_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.body).to include('target="dashboard_monthly_hours"')
    end

    it "AC3: responde com turbo-stream para atualizar valor do mês" do
      post tasks_path, params: valid_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.body).to include('target="dashboard_monthly_value"')
    end

    it "Story5.10: responde com turbo-stream para atualizar tasks hoje" do
      post tasks_path, params: valid_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.body).to include('target="dashboard_daily_task_count"')
    end

    it "Story5.10: responde com turbo-stream para atualizar tasks mês" do
      post tasks_path, params: valid_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.body).to include('target="dashboard_monthly_task_count"')
    end

    it "Story5.10: responde com turbo-stream para atualizar valor hoje" do
      post tasks_path, params: valid_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.body).to include('target="dashboard_daily_value"')
    end
  end

  # AC4: Validação — modal permanece aberto com erros
  describe "POST /tasks com dados inválidos e header Turbo-Frame: modal" do
    it "AC4: re-renderiza o form com status 422" do
      post tasks_path,
           params: { task: { name: "", code: "" } },
           headers: { "Turbo-Frame" => "modal" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Nova Tarefa")
    end
  end

  # GET /tasks/new sem header Turbo-Frame — renderização normal
  describe "GET /tasks/new sem header Turbo-Frame" do
    it "renderiza formulário normal sem overlay" do
      get new_task_path
      expect(response.body).not_to include("bg-black/50")
      expect(response.body).to include("Nova Tarefa")
    end

    it "HIGH-2: versão normal contém campo status" do
      get new_task_path
      expect(response.body).to include("task[status]")
    end

    it "MED-1: labels do status estão em português" do
      get new_task_path
      expect(response.body).to include("Pendente")
      expect(response.body).to include("Concluído")
      expect(response.body).to include("Entregue")
    end
  end

  # Totalizadores dinâmicos no dashboard
  describe "GET / (dashboard) com totalizadores dinâmicos" do
    it "HIGH-1: exibe card Horas Hoje com id turbo stream" do
      get root_path
      expect(response.body).to include('id="dashboard_daily_hours"')
    end

    it "HIGH-1: exibe card Horas Mês com id turbo stream" do
      get root_path
      expect(response.body).to include('id="dashboard_monthly_hours"')
    end

    it "HIGH-1: exibe card Valor Mês com id turbo stream" do
      get root_path
      expect(response.body).to include('id="dashboard_monthly_value"')
    end

    it "Story5.10: exibe card Tasks Hoje com id turbo stream" do
      get root_path
      expect(response.body).to include('id="dashboard_daily_task_count"')
    end

    it "Story5.10: exibe card Tasks Mês com id turbo stream" do
      get root_path
      expect(response.body).to include('id="dashboard_monthly_task_count"')
    end

    it "Story5.10: exibe card Valor Hoje com id turbo stream" do
      get root_path
      expect(response.body).to include('id="dashboard_daily_value"')
    end
  end
end
