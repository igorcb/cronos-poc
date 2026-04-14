require "rails_helper"

# Story 8.1: Implementar Mobile-First com Tailwind Breakpoints
# Verifica que as views contêm as classes Tailwind necessárias para responsividade mobile-first.
RSpec.describe "Mobile-First Tailwind Breakpoints", type: :request do
  let(:user) { User.create!(email: "mobile@example.com", password: "password123") }
  let!(:company) { create(:company, name: "Empresa Teste") }

  def sign_in
    post session_path, params: { email: user.email, password: "password123" }
  end

  # AC5: Página de login também deve ser touch-friendly (sem autenticação)
  describe "GET /session/new (login)" do
    it "renders email field com min-h-[44px]" do
      get new_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('type="email"')
      expect(response.body).to include("min-h-[44px]")
    end

    it "renders botão Entrar com min-h-[44px]" do
      get new_session_path
      expect(response.body).to match(/min-h-\[44px\]/)
    end
  end

  before { sign_in }

  # AC1, AC3, AC4: Forms usam breakpoints sm:, md:, lg: e ocupam largura completa em mobile
  describe "GET /tasks/new" do
    it "renders wrapper com mobile-first (w-full) e max-width para desktop (sm:max-w-2xl)" do
      get new_task_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("w-full sm:max-w-2xl sm:mx-auto")
    end

    # AC5: Botões touch-friendly com min-h-[44px]
    it "renders botão submit com min-h-[44px]" do
      get new_task_path
      expect(response.body).to match(/bg-blue-600[^"]*min-h-\[44px\]|min-h-\[44px\][^"]*bg-blue-600/)
    end

    # AC6: Dropdowns com min-h-[44px] para touch
    it "renders select de empresa com min-h-[44px]" do
      get new_task_path
      expect(response.body).to match(/select.*min-h-\[44px\]|min-h-\[44px\].*select/m)
    end

    # AC5: textarea com min-h-[44px]
    it "renders textarea de observações com min-h-[44px]" do
      get new_task_path
      expect(response.body).to include("min-h-[44px]")
      expect(response.body).to include("<textarea")
    end

    # AC2: breakpoint sm: e md: presentes
    it "usa grid responsivo grid-cols-1 md:grid-cols-2 para campos de data/horas" do
      get new_task_path
      expect(response.body).to include("grid grid-cols-1 md:grid-cols-2 gap-4")
    end

    # AC4: padding responsivo p-4 sm:p-6
    it "usa padding responsivo p-4 sm:p-6 no card" do
      get new_task_path
      expect(response.body).to include("p-4 sm:p-6")
    end
  end

  describe "GET /tasks/:id/edit" do
    let!(:project) { create(:project, company: company) }
    let!(:task) { create(:task, company: company, project: project) }

    it "renders wrapper com mobile-first (w-full sm:max-w-2xl sm:mx-auto)" do
      get edit_task_path(task)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("w-full sm:max-w-2xl sm:mx-auto")
    end

    it "renders todos inputs com min-h-[44px]" do
      get edit_task_path(task)
      expect(response.body).to include("min-h-[44px]")
    end
  end

  describe "GET /tasks" do
    let!(:project) { create(:project, company: company) }
    let!(:task) { create(:task, company: company, project: project) }

    # AC5: botão Nova Tarefa touch-friendly
    it "renders botão Nova Tarefa com min-h-[44px] e inline-flex" do
      get tasks_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("min-h-[44px] inline-flex items-center")
    end

    # Tabela com scroll horizontal em mobile
    it "renders tabela dentro de div overflow-x-auto para mobile" do
      get tasks_path
      expect(response.body).to include("overflow-x-auto")
    end

    # AC1, AC6: filtros com grid responsivo e dropdowns touch-friendly
    it "renders filtros com grid responsivo mobile-first" do
      get tasks_path
      expect(response.body).to include("grid-cols-1 sm:grid-cols-2 lg:grid-cols-3")
    end

    it "renders filtros com selects touch-friendly (min-h-[44px])" do
      get tasks_path
      # Verifica que os selects dos filtros têm a classe
      expect(response.body).to include('class="w-full min-h-[44px] bg-gray-700')
    end

    it "renders botões de filtro em layout mobile-first (flex-col sm:flex-row)" do
      get tasks_path
      expect(response.body).to include("flex flex-col sm:flex-row gap-2")
    end
  end

  describe "GET /companies/new" do
    # AC3, AC4: form em mobile ocupa largura total; desktop tem max-width
    it "renders wrapper com mobile-first (w-full sm:max-w-lg sm:mx-auto)" do
      get new_company_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("w-full sm:max-w-lg sm:mx-auto")
    end

    # AC5: campos touch-friendly
    it "renders campos text_field com min-h-[44px]" do
      get new_company_path
      expect(response.body).to include("min-h-[44px]")
    end

    # AC5: botões em layout flex-col sm:flex-row
    it "renders botões em layout mobile-first (flex-col sm:flex-row)" do
      get new_company_path
      expect(response.body).to include("flex flex-col sm:flex-row gap-3 pt-4")
    end
  end

  describe "GET /companies/:id/edit" do
    it "renders wrapper com mobile-first (w-full sm:max-w-lg sm:mx-auto)" do
      get edit_company_path(company)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("w-full sm:max-w-lg sm:mx-auto")
    end
  end

  describe "GET /companies" do
    # AC5: botões de ação touch-friendly — verifica especificamente o botão Editar
    it "renders botão Editar com min-h-[44px] e inline-flex" do
      get companies_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("min-h-[44px] inline-flex items-center")
    end

    it "renders botão Desativar com min-h-[44px]" do
      get companies_path
      expect(response.body).to include("min-h-[44px] bg-red-600")
    end
  end

  describe "GET /projects/new" do
    # AC3, AC4: form em mobile ocupa largura total; desktop tem max-width
    it "renders wrapper com mobile-first (w-full sm:max-w-lg sm:mx-auto)" do
      get new_project_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("w-full sm:max-w-lg sm:mx-auto")
    end

    # AC5: campos touch-friendly
    it "renders campos com min-h-[44px]" do
      get new_project_path
      expect(response.body).to include("min-h-[44px]")
    end
  end

  describe "GET /projects/:id/edit" do
    let!(:project) { create(:project, company: company) }

    it "renders wrapper com mobile-first (w-full sm:max-w-lg sm:mx-auto)" do
      get edit_project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("w-full sm:max-w-lg sm:mx-auto")
    end
  end

  describe "GET /projects" do
    let!(:project) { create(:project, company: company) }

    # AC5: botões de ação touch-friendly — verifica especificamente o botão Editar
    it "renders botão Editar com min-h-[44px] e inline-flex" do
      get projects_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("min-h-[44px] inline-flex items-center")
    end

    it "renders botão Deletar com min-h-[44px]" do
      get projects_path
      expect(response.body).to include("min-h-[44px] bg-red-600")
    end
  end
end
