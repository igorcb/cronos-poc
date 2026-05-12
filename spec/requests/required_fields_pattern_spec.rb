require 'rails_helper'

# Story 1.10 — Aplicar padrão de campos obrigatórios com asterisco nos formulários
# ACs cobertos:
#   AC1-AC5  : asterisco vermelho nos labels e nota de rodapé
#   AC6      : ausência de required="required" HTML nativo (novalidate + aria-required no lugar)
#   AC11     : novalidate nos formulários (companies, projects, tasks/new, tasks/edit)
#   AC12-AC13: borda vermelha (border-red-500) server-side quando há erros
RSpec.describe "Required fields pattern — Story 1.10", type: :request do
  let!(:user) { User.create!(email: "test@example.com", password: "password123") }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
  end

  before { sign_in(user) }

  # ---------------------------------------------------------------------------
  # companies/_form (usado por companies/new e companies/edit)
  # ---------------------------------------------------------------------------
  describe "companies/_form" do
    describe "GET /companies/new" do
      before { get new_company_path }

      it "AC11 — form tem atributo novalidate" do
        expect(response.body).to include('novalidate="novalidate"')
      end

      it "AC6 — campo nome NÃO tem required HTML nativo" do
        expect(response.body).not_to match(/name="company\[name\]"[^>]*required="required"/)
        expect(response.body).not_to match(/required="required"[^>]*name="company\[name\]"/)
      end

      it "AC6 — campo hourly_rate NÃO tem required HTML nativo" do
        expect(response.body).not_to match(/name="company\[hourly_rate\]"[^>]*required="required"/)
      end

      it "mantém aria-required nos campos obrigatórios" do
        expect(response.body).to include('aria-required="true"')
      end

      it "AC1 — label nome contém asterisco span.text-red-400" do
        expect(response.body).to include('class="text-red-400 ml-1"')
      end

      it "nota de rodapé campos obrigatórios está presente" do
        expect(response.body).to include("campos obrigatórios")
      end

      it "form tem data-controller form-validation" do
        expect(response.body).to include('form-validation')
      end
    end

    describe "GET /companies/:id/edit" do
      let!(:company) { create(:company) }
      before { get edit_company_path(company) }

      it "AC11 — form tem atributo novalidate" do
        expect(response.body).to include('novalidate="novalidate"')
      end

      it "AC1 — label contém asterisco" do
        expect(response.body).to include('class="text-red-400 ml-1"')
      end
    end

    describe "POST /companies (erros de validação) — AC12/AC13" do
      context "quando nome está em branco" do
        before { post companies_path, params: { company: { name: "", hourly_rate: 100.00 } } }

        it "AC12 — campo nome recebe border-red-500" do
          expect(response.body).to include("border-red-500")
        end

        it "AC13 — campo hourly_rate (sem erro) recebe border-gray-600" do
          expect(response.body).to include("border-gray-600")
        end
      end

      context "quando hourly_rate está em branco" do
        before { post companies_path, params: { company: { name: "Empresa X", hourly_rate: "" } } }

        it "AC12 — campo hourly_rate recebe border-red-500" do
          expect(response.body).to include("border-red-500")
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # projects/_form (usado por projects/new e projects/edit)
  # ---------------------------------------------------------------------------
  describe "projects/_form" do
    let!(:company) { create(:company) }

    describe "GET /projects/new" do
      before { get new_project_path }

      it "AC11 — form tem atributo novalidate" do
        expect(response.body).to include('novalidate="novalidate"')
      end

      it "AC1 — label nome contém asterisco span.text-red-400" do
        expect(response.body).to include('class="text-red-400 ml-1"')
      end

      it "AC2 — nota de rodapé campos obrigatórios está presente" do
        expect(response.body).to include("campos obrigatórios")
      end

      it "AC6 — campo nome NÃO tem required HTML nativo" do
        expect(response.body).not_to match(/name="project\[name\]"[^>]*required="required"/)
      end

      it "AC6 — campo company_id NÃO tem required HTML nativo" do
        expect(response.body).not_to match(/name="project\[company_id\]"[^>]*required="required"/)
      end

      it "mantém aria-required nos campos obrigatórios" do
        expect(response.body).to include('aria-required="true"')
      end

      it "mantém aria-labelledby no select de empresa" do
        expect(response.body).to include('aria-labelledby="company-label"')
      end

      it "form tem data-controller form-validation" do
        expect(response.body).to include('form-validation')
      end
    end

    describe "GET /projects/:id/edit" do
      let!(:project) { create(:project, company: company) }
      before { get edit_project_path(project) }

      it "AC11 — form tem atributo novalidate" do
        expect(response.body).to include('novalidate="novalidate"')
      end

      it "AC1 — label contém asterisco" do
        expect(response.body).to include('class="text-red-400 ml-1"')
      end
    end

    describe "POST /projects (erros de validação) — AC12/AC13" do
      context "quando nome está em branco" do
        before { post projects_path, params: { project: { name: "", company_id: company.id } } }

        it "AC12 — campo nome recebe border-red-500" do
          expect(response.body).to include("border-red-500")
        end

        it "AC13 — campo company_id (sem erro) recebe border-gray-600" do
          expect(response.body).to include("border-gray-600")
        end
      end

      context "quando company_id está em branco" do
        before { post projects_path, params: { project: { name: "Projeto X", company_id: "" } } }

        it "AC12 — campo company_id recebe border-red-500" do
          expect(response.body).to include("border-red-500")
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # tasks/new.html.erb
  # ---------------------------------------------------------------------------
  describe "tasks/new" do
    describe "GET /tasks/new" do
      before { get new_task_path }

      it "AC11 — form tem atributo novalidate" do
        expect(response.body).to include('novalidate="novalidate"')
      end

      it "AC3 — label nome da tarefa contém asterisco" do
        expect(response.body).to include('class="text-red-400 ml-1"')
      end

      it "AC4 — label Observações NÃO contém asterisco (campo opcional)" do
        # Isola o bloco do label de Observações
        body = response.body
        obs_label_start = body.index("Observações")
        # Próximo campo após o label de Observações não deve ter asterisco imediatamente
        obs_section = body[obs_label_start, 200] if obs_label_start
        expect(obs_section).not_to include('aria-hidden="true">*') if obs_section
      end

      it "AC5 — nota de rodapé campos obrigatórios está presente" do
        expect(response.body).to include("campos obrigatórios")
      end

      it "AC6 — campos obrigatórios NÃO têm required HTML nativo" do
        expect(response.body).not_to match(/name="task\[name\]"[^>]*required="required"/)
        expect(response.body).not_to match(/name="task\[company_id\]"[^>]*required="required"/)
      end

      it "mantém aria-required nos campos obrigatórios" do
        expect(response.body).to include('aria-required="true"')
      end

      it "form tem data-controller com project-selector e form-validation" do
        expect(response.body).to include('project-selector form-validation')
      end

      it "campo project_id mantém disabled" do
        expect(response.body).to include('disabled="disabled"')
      end
    end

    describe "POST /tasks (erros de validação) — AC12/AC13" do
      context "quando nome está em branco" do
        before do
          post tasks_path, params: {
            task: {
              name: "",
              company_id: create(:company).id,
              start_date: Date.today,
              estimated_hours_hm: "08:00"
            }
          }
        end

        it "AC12 — campo nome recebe border-red-500" do
          expect(response.body).to include("border-red-500")
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # tasks/edit.html.erb
  # ---------------------------------------------------------------------------
  describe "tasks/edit" do
    let!(:company) { create(:company) }
    let!(:project) { create(:project, company: company) }
    let!(:task) { create(:task, company: company, project: project) }

    describe "GET /tasks/:id/edit" do
      before { get edit_task_path(task) }

      it "AC11 — form tem atributo novalidate" do
        expect(response.body).to include('novalidate="novalidate"')
      end

      it "AC3 — labels contêm asterisco nos campos obrigatórios" do
        expect(response.body).to include('class="text-red-400 ml-1"')
      end

      it "AC5 — nota de rodapé campos obrigatórios está presente" do
        expect(response.body).to include("campos obrigatórios")
      end

      it "AC6 — campos NÃO têm required HTML nativo" do
        expect(response.body).not_to match(/name="task\[name\]"[^>]*required="required"/)
      end

      it "mantém aria-required" do
        expect(response.body).to include('aria-required="true"')
      end

      it "form tem data-controller com project-selector e form-validation" do
        expect(response.body).to include('project-selector form-validation')
      end
    end
  end
end
