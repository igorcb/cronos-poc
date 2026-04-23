require "rails_helper"

# Story 5.7: Substituir Seção "Ações Rápidas" por Ícone de Nova Tarefa
RSpec.describe "Dashboard Quick Actions", type: :request do
  let(:user) { User.create!(email: "dashboard_qa@example.com", password: "password123") }

  def sign_in
    post session_path, params: { email: user.email, password: "password123" }
  end

  before { sign_in }

  describe "GET / (dashboard)" do
    before { get root_path }

    # AC1: Seção "Ações Rápidas" removida
    it "AC1: não exibe seção Ações Rápidas com aria-labelledby" do
      expect(response.body).not_to include("quick-actions-heading")
    end

    it "AC1: não exibe título Ações Rápidas" do
      expect(response.body).not_to include("Ações Rápidas")
    end

    # AC2: Ícone + presente — verificações com strings únicas do elemento alvo
    it "AC2: ícone SVG + com path exclusivo M12 4v16m8-8H4" do
      expect(response.body).to include("M12 4v16m8-8H4")
    end

    it "AC2: link do ícone aponta para /tasks/new contendo path SVG +" do
      expect(response.body).to include(new_task_path)
      expect(response.body).to include("M12 4v16m8-8H4")
    end

    it "AC2: aria-label Nova Tarefa presente no link" do
      expect(response.body).to include('aria-label="Nova Tarefa"')
    end

    # AC3: Seção "Ação rápida" existe (posicionamento substituído)
    it "AC3: seção aria-label Ação rápida está presente" do
      expect(response.body).to include('aria-label="Ação rápida"')
    end

    # AC4: Sem texto visível
    it "AC4: não exibe emoji de relógio com texto Nova Tarefa" do
      expect(response.body).not_to include("⏱️ Nova Tarefa")
    end

    it "AC4: não exibe card wrapper quick-actions-heading na seção de ação rápida" do
      expect(response.body).not_to include("quick-actions-heading")
    end
  end

  describe "GET / sem autenticação" do
    it "redireciona para login quando não autenticado" do
      # nova sessão sem sign_in
      get root_path, headers: { "HTTP_COOKIE" => "" }
      expect(response).to redirect_to(new_session_path)
    end
  end
end
