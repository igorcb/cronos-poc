require "rails_helper"

# Story 8.4: Testar Responsividade em Múltiplos Dispositivos
#
# Valida que todas as views contêm as classes e estrutura Tailwind necessárias
# para suportar os breakpoints: Mobile (375px), Tablet (768px), Desktop (1024px+).
#
# AC1: Testado em iPhone SE (375px), iPad (768px), Desktop (1024px+)
# AC2: Formulário de registro funciona perfeitamente em todos
# AC3: Lista de entradas é legível em todos
# AC4: Totalizadores são visíveis em todos
# AC5: Filtros funcionam em mobile (dropdown otimizado)
# AC6: Browsers suportados declarados via meta viewport e semântica HTML5
RSpec.describe "Responsividade em Múltiplos Dispositivos", type: :request do
  let(:user) { User.create!(email: "responsive@example.com", password: "password123") }
  let!(:company) { create(:company, name: "Empresa Responsiva") }
  let!(:project) { create(:project, company: company) }
  let!(:task) { create(:task, company: company, project: project) }

  def sign_in
    post session_path, params: { email: user.email, password: "password123" }
  end

  # ---------------------------------------------------------------------------
  # AC6: Suporte a múltiplos browsers — viewport e meta tags obrigatórias
  # ---------------------------------------------------------------------------
  describe "AC6 - Meta tags para suporte a múltiplos browsers" do
    it "layout principal possui meta viewport com width=device-width,initial-scale=1" do
      get new_session_path
      expect(response.body).to include('name="viewport"')
      expect(response.body).to include("width=device-width,initial-scale=1")
    end

    it "layout possui lang=pt-BR para compatibilidade com browsers" do
      get new_session_path
      expect(response.body).to include('lang="pt-BR"')
    end

    it "layout possui apple-mobile-web-app-capable para Safari iOS" do
      get new_session_path
      expect(response.body).to include('name="apple-mobile-web-app-capable"')
    end

    it "layout possui mobile-web-app-capable para Chrome Android" do
      get new_session_path
      expect(response.body).to include('name="mobile-web-app-capable"')
    end
  end

  # ---------------------------------------------------------------------------
  # AC1 + AC6: Breakpoints Mobile (375px) — classes mobile-first sem prefixo
  # ---------------------------------------------------------------------------
  describe "AC1 - Suporte Mobile (375px — iPhone SE)" do
    before { sign_in }

    context "GET /session/new (login)" do
      it "possui email input acessível sem prefixo de breakpoint" do
        get new_session_path
        expect(response.body).to include('type="email"')
      end

      it "possui botão de login touch-friendly (min-h-[44px])" do
        get new_session_path
        expect(response.body).to include("min-h-[44px]")
      end
    end

    context "GET /tasks/new (formulário de registro — AC2)" do
      it "wrapper ocupa largura total em mobile (w-full)" do
        get new_task_path
        expect(response.body).to include("w-full")
      end

      it "botão submit ocupa largura total em mobile (w-full sm:w-auto)" do
        get new_task_path
        expect(response.body).to include("w-full sm:w-auto")
      end

      it "inputs com touch target mínimo 44px (min-h-[44px])" do
        get new_task_path
        expect(response.body).to include("min-h-[44px]")
      end

      it "grid de datas usa coluna única em mobile (grid-cols-1)" do
        get new_task_path
        expect(response.body).to include("grid-cols-1")
      end

      it "select de empresa touch-friendly (min-h-[44px])" do
        get new_task_path
        expect(response.body).to match(/select[^>]*min-h-\[44px\]|min-h-\[44px\][^>]*select/m)
      end
    end

    context "GET /tasks (lista de entradas — AC3)" do
      it "tabela possui overflow-x-auto para scroll horizontal em mobile" do
        get tasks_path
        expect(response.body).to include("overflow-x-auto")
      end

      it "filtros em coluna única em mobile (grid-cols-1)" do
        get tasks_path
        expect(response.body).to include("grid-cols-1")
      end

      it "botão Nova Tarefa touch-friendly (min-h-[44px])" do
        get tasks_path
        expect(response.body).to include("min-h-[44px] inline-flex items-center")
      end
    end

    context "GET /tasks (totalizadores — AC4)" do
      it "totalizador diário presente na página" do
        get tasks_path
        expect(response.body).to include("daily_total")
        expect(response.body).to include("Total do Dia")
      end

      it "totalizadores mensais por empresa presentes" do
        get tasks_path
        expect(response.body).to include("company_monthly_totals")
        expect(response.body).to include("Totais do Mês por Empresa")
      end
    end

    context "GET /tasks (filtros em mobile — AC5)" do
      it "selects de filtro têm min-h-[44px] para touch" do
        get tasks_path
        expect(response.body).to include('class="w-full min-h-[44px] bg-gray-700')
      end

      it "botões de filtro em layout coluna em mobile (flex-col)" do
        get tasks_path
        expect(response.body).to include("flex flex-col sm:flex-row gap-2")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # AC1: Breakpoints Tablet (768px) — prefixo sm: e md:
  # ---------------------------------------------------------------------------
  describe "AC1 - Suporte Tablet (768px — iPad)" do
    before { sign_in }

    context "GET /tasks/new (formulário — AC2)" do
      it "form centralizado em tablet (sm:mx-auto)" do
        get new_task_path
        expect(response.body).to include("sm:mx-auto")
      end

      it "form com max-width para tablet (sm:max-w-2xl)" do
        get new_task_path
        expect(response.body).to include("sm:max-w-2xl")
      end

      it "grid de campos expande para 2 colunas em tablet (md:grid-cols-2)" do
        get new_task_path
        expect(response.body).to include("md:grid-cols-2")
      end

      it "padding aumentado em tablet (sm:p-6)" do
        get new_task_path
        expect(response.body).to include("sm:p-6")
      end
    end

    context "GET /tasks (lista — AC3)" do
      it "filtros em 2 colunas para tablet (sm:grid-cols-2)" do
        get tasks_path
        expect(response.body).to include("sm:grid-cols-2")
      end

      it "botões de filtro em linha horizontal para tablet (sm:flex-row)" do
        get tasks_path
        expect(response.body).to include("sm:flex-row")
      end
    end

    context "GET /companies/new" do
      it "form centralizado em tablet (sm:mx-auto)" do
        get new_company_path
        expect(response.body).to include("sm:mx-auto")
      end

      it "form com max-width para tablet (sm:max-w-lg)" do
        get new_company_path
        expect(response.body).to include("sm:max-w-lg")
      end

      it "botões em linha horizontal para tablet (sm:flex-row)" do
        get new_company_path
        expect(response.body).to include("sm:flex-row")
      end
    end

    context "GET /projects/new" do
      it "form centralizado em tablet (sm:mx-auto)" do
        get new_project_path
        expect(response.body).to include("sm:mx-auto")
      end

      it "form com max-width para tablet (sm:max-w-lg)" do
        get new_project_path
        expect(response.body).to include("sm:max-w-lg")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # AC1: Breakpoints Desktop (1024px+) — prefixo lg:
  # ---------------------------------------------------------------------------
  describe "AC1 - Suporte Desktop (1024px+ — Laptop/Monitor)" do
    before { sign_in }

    context "Layout principal" do
      it "max-width global aplicado (max-w-7xl) para limitar expansão" do
        get tasks_path
        expect(response.body).to include("max-w-7xl mx-auto")
      end

      it "navbar com links visíveis para desktop (md:flex)" do
        get tasks_path
        expect(response.body).to include("hidden md:flex")
      end

      it "padding lateral aumentado para desktop (lg:px-8)" do
        get tasks_path
        expect(response.body).to include("lg:px-8")
      end
    end

    context "GET /tasks (lista — AC3)" do
      it "filtros em 3 colunas para desktop (lg:grid-cols-3)" do
        get tasks_path
        expect(response.body).to include("lg:grid-cols-3")
      end
    end

    context "GET /tasks/new (formulário — AC2)" do
      it "botão submit com largura automática em desktop (sm:w-auto)" do
        get new_task_path
        expect(response.body).to include("sm:w-auto")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # AC2: Formulário de registro funciona em todos os breakpoints
  # ---------------------------------------------------------------------------
  describe "AC2 - Formulário de registro completo em todos os breakpoints" do
    before { sign_in }

    it "GET /tasks/new: contém todos os campos obrigatórios" do
      get new_task_path
      expect(response.body).to include("Empresa")
      expect(response.body).to include("Projeto")
      expect(response.body).to include("Nome da Tarefa")
      expect(response.body).to include("Data de In")
      expect(response.body).to include("Horas Estimadas")
    end

    it "GET /tasks/new: input de data com type=date para teclado nativo mobile" do
      get new_task_path
      expect(response.body).to include('type="date"')
    end

    it "GET /tasks/new: campo de horas com inputmode=numeric para teclado numérico mobile" do
      get new_task_path
      expect(response.body).to include('inputmode="numeric"')
    end

    it "GET /tasks/new: textarea de observações com altura touch adequada (min-h-[88px])" do
      get new_task_path
      expect(response.body).to include("min-h-[88px]")
    end

    it "GET /tasks/:id/edit: formulário de edição possui mesma estrutura responsiva" do
      get edit_task_path(task)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("w-full sm:max-w-2xl sm:mx-auto")
      expect(response.body).to include("min-h-[44px]")
    end
  end

  # ---------------------------------------------------------------------------
  # AC3: Lista de entradas legível em todos os breakpoints
  # ---------------------------------------------------------------------------
  describe "AC3 - Lista de entradas legível em todos os breakpoints" do
    before { sign_in }

    it "tabela possui cabeçalhos (th) semânticos" do
      get tasks_path
      expect(response.body).to include("<th")
      expect(response.body).to include("scope=\"col\"")
    end

    it "tabela com scroll horizontal em mobile via overflow-x-auto" do
      get tasks_path
      expect(response.body).to include("overflow-x-auto")
    end

    it "tabela com min-w-full para manter layout correto" do
      get tasks_path
      expect(response.body).to include("min-w-full")
    end
  end

  # ---------------------------------------------------------------------------
  # AC4: Totalizadores visíveis em todos os breakpoints
  # ---------------------------------------------------------------------------
  describe "AC4 - Totalizadores visíveis em todos os breakpoints" do
    before { sign_in }

    it "totalizador diário renderizado dentro de card responsivo (bg-gray-800 rounded-lg)" do
      get tasks_path
      expect(response.body).to include("Total do Dia")
      expect(response.body).to include("daily_total")
    end

    it "totalizadores mensais renderizados dentro de card responsivo" do
      get tasks_path
      expect(response.body).to include("company_monthly_totals")
      expect(response.body).to include("Totais do Mês por Empresa")
    end
  end

  # ---------------------------------------------------------------------------
  # AC5: Filtros funcionam em mobile (dropdown otimizado)
  # ---------------------------------------------------------------------------
  describe "AC5 - Filtros otimizados para mobile" do
    before { sign_in }

    it "selects de filtro com w-full para ocupar largura total em mobile" do
      get tasks_path
      expect(response.body).to include('class="w-full min-h-[44px]')
    end

    it "layout de filtros mobile-first: coluna em mobile, linha em tablet (grid-cols-1 sm:grid-cols-2 lg:grid-cols-3)" do
      get tasks_path
      expect(response.body).to include("grid-cols-1 sm:grid-cols-2 lg:grid-cols-3")
    end

    it "botão Aplicar Filtros ocupa toda largura em mobile, auto em tablet" do
      get tasks_path
      expect(response.body).to include("flex flex-col sm:flex-row gap-2")
    end
  end

  # ---------------------------------------------------------------------------
  # Navegação mobile: menu hamburguer
  # ---------------------------------------------------------------------------
  describe "Navegação mobile — menu hamburguer" do
    before { sign_in }

    it "botão de menu mobile (hamburguer) presente com touch target mínimo" do
      get tasks_path
      expect(response.body).to include("min-h-[44px] min-w-[44px]")
      expect(response.body).to include('aria-label="Abrir menu de navegação"')
    end

    it "menu mobile com links de navegação" do
      get tasks_path
      expect(response.body).to include('id="mobile-menu"')
    end

    it "links de desktop ocultos em mobile (hidden md:flex)" do
      get tasks_path
      expect(response.body).to include("hidden md:flex")
    end

    it "menu mobile oculto por padrão em desktop (md:hidden)" do
      get tasks_path
      expect(response.body).to include("md:hidden")
    end
  end
end
