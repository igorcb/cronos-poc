require "rails_helper"

# Story 8.2: Otimizar TimeEntry Form para Mobile
# Verifica que os formulários de Task têm inputs otimizados para teclados mobile,
# touch targets adequados e validações client-side.
RSpec.describe "Mobile TimeEntry Form Optimization", type: :request do
  let(:user) { User.create!(email: "mobile_form@example.com", password: "password123") }
  let!(:company) { create(:company, name: "Empresa Mobile") }
  let!(:project) { create(:project, company: company) }
  let!(:task) { create(:task, company: company, project: project) }

  def sign_in
    post session_path, params: { email: user.email, password: "password123" }
  end

  before { sign_in }

  # AC1: Inputs de data usam type correto
  describe "AC1 - Input de data com type='date'" do
    it "GET /tasks/new: start_date usa type=date (teclado de data nativo)" do
      get new_task_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('type="date"')
    end

    it "GET /tasks/:id/edit: start_date usa type=date" do
      get edit_task_path(task)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('type="date"')
    end
  end

  # AC2: Teclado mobile abre com tipo correto
  describe "AC2 - Teclado mobile correto para campo de horas" do
    it "GET /tasks/new: campo estimated_hours_hm tem inputmode=numeric" do
      get new_task_path
      expect(response.body).to include('inputmode="numeric"')
    end

    it "GET /tasks/:id/edit: campo estimated_hours_hm tem inputmode=numeric" do
      get edit_task_path(task)
      expect(response.body).to include('inputmode="numeric"')
    end
  end

  # AC3: Labels claras e visíveis
  describe "AC3 - Labels claras e visíveis" do
    it "GET /tasks/new: label 'Empresa' presente e associada ao select" do
      get new_task_path
      expect(response.body).to include("Empresa")
      expect(response.body).to include("Projeto")
      expect(response.body).to include("Nome da Tarefa")
      expect(response.body).to include("Data de In")
      expect(response.body).to include("Horas Estimadas")
    end

    it "GET /tasks/:id/edit: todas as labels presentes" do
      get edit_task_path(task)
      expect(response.body).to include("Empresa")
      expect(response.body).to include("Projeto")
      expect(response.body).to include("Nome da Tarefa")
    end
  end

  # AC4: Textarea com altura adequada para touch (min-h-[88px])
  describe "AC4 - Textarea com min-h-[88px] para touch" do
    it "GET /tasks/new: textarea de observações tem min-h-[88px]" do
      get new_task_path
      expect(response.body).to match(/textarea[^>]*min-h-\[88px\]|min-h-\[88px\][^>]*textarea/m)
    end

    it "GET /tasks/:id/edit: textarea de observações tem min-h-[88px]" do
      get edit_task_path(task)
      expect(response.body).to match(/textarea[^>]*min-h-\[88px\]|min-h-\[88px\][^>]*textarea/m)
    end

    it "GET /tasks/new: textarea NÃO tem apenas min-h-[44px] (altura insuficiente para touch)" do
      get new_task_path
      # A textarea deve ter min-h-[88px], não a altura mínima de 44px
      expect(response.body).to include("min-h-[88px]")
    end
  end

  # AC5: Botão submit destacado e grande
  describe "AC5 - Botão submit touch-friendly e destacado" do
    it "GET /tasks/new: submit tem w-full para ocupar toda largura mobile" do
      get new_task_path
      # Verificar que o botão submit tem w-full sm:w-auto (mobile ocupa 100%, desktop auto)
      expect(response.body).to include("w-full sm:w-auto")
    end

    it "GET /tasks/new: submit tem min-h-[44px] para touch target mínimo" do
      get new_task_path
      expect(response.body).to include("min-h-[44px]")
    end

    it "GET /tasks/new: submit tem bg-blue-600 para destaque visual" do
      get new_task_path
      expect(response.body).to include("bg-blue-600")
    end

    it "GET /tasks/:id/edit: submit tem w-full sm:w-auto" do
      get edit_task_path(task)
      expect(response.body).to include("w-full sm:w-auto")
    end
  end

  # AC6: Validações client-side funcionam em mobile
  describe "AC6 - Validações client-side para mobile" do
    it "GET /tasks/new: campo estimated_hours_hm tem pattern para formato HH:MM" do
      get new_task_path
      expect(response.body).to match(/pattern=["']\\d\{1,2\}:\\d\{2\}["']/)
    end

    it "GET /tasks/new: campo estimated_hours_hm tem title explicando o formato" do
      get new_task_path
      expect(response.body).to include("Formato HH:MM")
    end

    it "GET /tasks/new: campo nome tem aria-required para validação Stimulus (story 1.10)" do
      get new_task_path
      # Story 1.10: required nativo removido; Stimulus form-validation usa aria-required
      expect(response.body).to include('aria-required="true"')
      expect(response.body).not_to include('required="required"')
    end

    it "GET /tasks/new: data de início tem aria-required e type=date" do
      get new_task_path
      expect(response.body).to include('type="date"')
      expect(response.body).to include('aria-required="true"')
    end

    it "GET /tasks/:id/edit: campo estimated_hours_hm tem pattern HH:MM" do
      get edit_task_path(task)
      expect(response.body).to match(/pattern=["']\\d\{1,2\}:\\d\{2\}["']/)
    end
  end
end
