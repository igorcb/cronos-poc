require "rails_helper"

# Story 4.12: Simplificar Ações Rápidas no Dashboard
RSpec.describe "Dashboard Quick Actions", type: :request do
  let(:user) { User.create!(email: "dashboard_qa@example.com", password: "password123") }

  def sign_in
    post session_path, params: { email: user.email, password: "password123" }
  end

  before { sign_in }

  describe "GET / (dashboard)" do
    before { get root_path }

    # AC1: Apenas 1 botão: "Nova Tarefa"
    it "AC1: exibe botão Nova Tarefa" do
      expect(response.body).to include("Nova Tarefa")
    end

    # AC2: Cards de Empresas e Projetos removidos
    it "AC2: não exibe card de Empresas na seção de ações rápidas" do
      expect(response.body).not_to include("🏢 Empresas")
    end

    it "AC2: não exibe card de Projetos na seção de ações rápidas" do
      expect(response.body).not_to include("📁 Projetos")
    end

    # AC3: Botão aponta para new_task_path
    it "AC3: botão Nova Tarefa aponta para /tasks/new" do
      expect(response.body).to include(new_task_path)
    end

    # AC4: Layout sem grid de 3 colunas para 1 item
    it "AC4: não usa grid de 3 colunas na seção de ações rápidas" do
      expect(response.body).not_to include("lg:grid-cols-3")
    end

    # AC5: Texto atualizado de "Nova Entrada" para "Nova Tarefa"
    it "AC5: não exibe texto Nova Entrada" do
      expect(response.body).not_to include("Nova Entrada")
    end

    it "AC5: exibe texto Nova Tarefa" do
      expect(response.body).to include("Nova Tarefa")
    end

    # AC6: aria-label atualizado
    it "AC6: aria-label correto para Nova Tarefa" do
      expect(response.body).to include("Nova Tarefa - Registrar nova tarefa")
    end
  end
end
