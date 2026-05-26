require "rails_helper"

# Story 9.3 — DM-008: Onboarding no primeiro acesso de novo usuário.
RSpec.describe "Dashboard onboarding", type: :request do
  let!(:user) { User.create!(email: "onboarding_dashboard@example.com", password: "password123", name: "Maria Souza") }

  def sign_in(u = user)
    post session_path, params: { email: u.email, password: "password123" }
  end

  before { sign_in }

  context "AC1/AC2 — user sem nenhuma Company (step_1)" do
    it "renderiza partial de onboarding com boas-vindas usando primeiro nome" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Olá, Maria")
      expect(response.body).to include("Vamos configurar seu Cronos POC em 3 passos rápidos")
    end

    it "não renderiza a tabela de tarefas do mês" do
      get root_path
      expect(response.body).not_to include("Tarefas do Mês")
    end

    it "exibe CTA 'Criar Empresa' apontando para new_company_path no passo 1" do
      get root_path
      expect(response.body).to match(/<a[^>]*data-onboarding-cta="step_1"[^>]*href="#{Regexp.escape(new_company_path)}"/)
    end

    it "trava o passo 2 (Criar Projeto) com mensagem orientativa" do
      get root_path
      expect(response.body).to include("Crie primeiro uma Empresa para depois adicionar Projetos")
      expect(response.body).to include('data-onboarding-state="locked"')
    end

    it "trava o passo 3 (Criar Tarefa)" do
      get root_path
      # Dois cards locked (steps 2 e 3) quando estamos em step_1
      expect(response.body.scan('data-onboarding-state="locked"').size).to eq(2)
    end
  end

  context "AC2.4 — user com 1 Company e 0 Projects (step_2)" do
    let!(:company) { create(:company, user: user, name: "Acme") }

    it "marca passo 1 como done e habilita passo 2" do
      get root_path
      expect(response.body).to include('data-onboarding-state="done"')
      expect(response.body).to match(/<a[^>]*data-onboarding-cta="step_2"[^>]*href="#{Regexp.escape(new_project_path)}"/)
    end

    it "mantém passo 3 (Criar Tarefa) bloqueado" do
      get root_path
      expect(response.body.scan('data-onboarding-state="locked"').size).to eq(1)
    end
  end

  context "AC2.5 — user com 1 Project e 0 Tasks (step_3)" do
    let!(:company) { create(:company, user: user) }
    let!(:project) { create(:project, company: company, user: user) }

    it "habilita CTA 'Criar Primeira Tarefa'" do
      get root_path
      expect(response.body).to match(/<a[^>]*data-onboarding-cta="step_3"[^>]*href="#{Regexp.escape(new_task_path)}"/)
    end

    it "marca passos 1 e 2 como done" do
      get root_path
      expect(response.body.scan('data-onboarding-state="done"').size).to eq(2)
    end
  end

  context "AC2.6/AC5 — user com 1 Task (completed): dashboard normal" do
    let!(:company) { create(:company, user: user) }
    let!(:project) { create(:project, company: company, user: user) }
    let!(:task)    { create(:task, company: company, project: project, user: user) }

    it "não renderiza o partial de onboarding" do
      get root_path
      expect(response.body).not_to include("Vamos configurar seu Cronos POC")
    end

    it "renderiza a tabela 'Tarefas do Mês' do dashboard normal" do
      get root_path
      expect(response.body).to include("Tarefas do Mês")
    end
  end

  context "AC4.2 — POST /companies redireciona para /projects/new durante onboarding" do
    it "redireciona para new_project_path com flash apropriado" do
      post companies_path, params: { company: { name: "Nova", hourly_rate: 100.00 } }
      expect(response).to redirect_to(new_project_path)
      follow_redirect!
      expect(response.body).to include("Empresa criada! Agora crie seu primeiro projeto.")
    end
  end

  context "AC — POST /companies fora do onboarding mantém destino padrão" do
    before { complete_onboarding_for(user) }

    it "redireciona para companies_path" do
      post companies_path, params: { company: { name: "Outra", hourly_rate: 100.00 } }
      expect(response).to redirect_to(companies_path)
      follow_redirect!
      expect(response.body).to include("Empresa cadastrada com sucesso")
    end
  end

  context "AC4.4 — POST /projects redireciona para root_path durante onboarding" do
    let!(:company) { create(:company, user: user) }

    it "redireciona ao dashboard com flash de onboarding" do
      post projects_path, params: { project: { name: "Proj X", company_id: company.id } }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Projeto criado! Agora lance sua primeira tarefa.")
    end
  end

  # QA #M4 — user em :step_3 criando SEGUNDO project ainda está no onboarding,
  # então volta ao dashboard (não para projects_path).
  context "QA #M4 — POST /projects em :step_3 (segundo project, ainda sem task)" do
    let!(:company) { create(:company, user: user) }
    let!(:first_project) { create(:project, company: company, user: user) }

    it "ainda redireciona ao root_path porque onboarding continua ativo" do
      post projects_path, params: { project: { name: "Segundo", company_id: company.id } }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Projeto criado! Agora lance sua primeira tarefa.")
    end
  end

  context "AC — POST /projects fora do onboarding mantém destino padrão" do
    let!(:company) { create(:company, user: user) }
    before { complete_onboarding_for(user) }

    it "redireciona para projects_path" do
      post projects_path, params: { project: { name: "Outro", company_id: company.id } }
      expect(response).to redirect_to(projects_path)
      follow_redirect!
      expect(response.body).to include("Projeto cadastrado com sucesso")
    end
  end

  context "AC4.5 — POST /tasks (HTML) primeira task mostra flash de conclusão" do
    let!(:company) { create(:company, user: user) }
    let!(:project) { create(:project, company: company, user: user) }

    let(:valid_task_params) do
      {
        task: {
          code: "99001",
          name: "Primeira tarefa",
          company_id: company.id,
          project_id: project.id,
          start_date: Date.current.to_s,
          end_date: (Date.current + 7.days).to_s,
          estimated_hours_hm: "02:00"
        }
      }
    end

    it "redireciona ao tasks_path com flash de conclusão do onboarding" do
      post tasks_path, params: valid_task_params
      expect(response).to redirect_to(tasks_path)
      follow_redirect!
      expect(response.body).to include("Configuração concluída")
    end

    it "tasks subsequentes mostram flash padrão" do
      create(:task, company: company, project: project, user: user)
      post tasks_path, params: valid_task_params
      follow_redirect!
      expect(response.body).to include("Tarefa criada com sucesso")
      expect(response.body).not_to include("Configuração concluída")
    end
  end

  # QA #H1 — primeira task via modal (Turbo-Frame=modal) deve disparar flash de conclusão.
  context "QA #H1 — POST /tasks (Turbo-Frame=modal) primeira task" do
    let!(:company) { create(:company, user: user) }
    let!(:project) { create(:project, company: company, user: user) }

    let(:valid_task_params) do
      {
        task: {
          code: "99002",
          name: "Primeira tarefa via modal",
          company_id: company.id,
          project_id: project.id,
          start_date: Date.current.to_s,
          end_date: (Date.current + 7.days).to_s,
          estimated_hours_hm: "02:00"
        }
      }
    end

    it "inclui flash de conclusão no turbo_stream update" do
      post tasks_path, params: valid_task_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.media_type).to eq Mime[:turbo_stream].to_s
      expect(response.body).to include('turbo-stream action="update" target="flash"')
      expect(response.body).to include("Configuração concluída")
    end

    it "tasks subsequentes via modal mostram flash padrão" do
      create(:task, company: company, project: project, user: user)
      post tasks_path, params: valid_task_params, headers: { "Turbo-Frame" => "modal" }
      expect(response.body).to include("Tarefa criada com sucesso")
      expect(response.body).not_to include("Configuração concluída")
    end
  end

  context "AC4.1 — /companies/new mostra header 'Passo 1 de 3' durante onboarding" do
    it "exibe label do passo" do
      get new_company_path
      expect(response.body).to include("Passo 1 de 3 — Criar Empresa")
    end

    it "não exibe label quando onboarding já completou" do
      complete_onboarding_for(user)
      get new_company_path
      expect(response.body).not_to include("Passo 1 de 3")
    end
  end

  context "AC4.3 — /projects/new mostra header 'Passo 2 de 3' durante onboarding" do
    let!(:company) { create(:company, user: user) }

    it "exibe label do passo" do
      get new_project_path
      expect(response.body).to include("Passo 2 de 3 — Criar Projeto")
    end

    it "não exibe label fora do onboarding" do
      project = create(:project, company: company, user: user)
      create(:task, company: company, project: project, user: user)
      get new_project_path
      expect(response.body).not_to include("Passo 2 de 3")
    end
  end

  context "AC2 — fallback de nome quando user.name está vazio" do
    let!(:other_user) { User.create!(email: "noname@example.com", password: "password123") }

    before do
      delete session_path
      sign_in(other_user)
    end

    it "usa o prefixo do email como saudação" do
      get root_path
      expect(response.body).to include("Olá, noname")
    end
  end
end
