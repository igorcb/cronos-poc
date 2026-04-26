require "rails_helper"

# Story 5.10: Expandir KPIs do Dashboard — 6 Métricas Globais
RSpec.describe "Dashboard KPIs", type: :request do
  let(:user) { User.create!(email: "dashboard_kpis@example.com", password: "password123") }
  let(:company) { create(:company, hourly_rate: 100.00) }
  let(:project) { create(:project, company: company) }

  def sign_in
    post session_path, params: { email: user.email, password: "password123" }
  end

  before { sign_in }

  describe "GET / (dashboard#index)" do
    context "with task_items today and in previous days" do
      let!(:task_today) do
        create(:task, company: company, project: project, start_date: Date.current)
      end
      let!(:task_yesterday) do
        create(:task, company: company, project: project, start_date: Date.current - 1.day)
      end
      let!(:task_this_month_no_items) do
        create(:task, company: company, project: project, start_date: Date.current.beginning_of_month)
      end

      let!(:item_today_2h) do
        create(:task_item, task: task_today, work_date: Date.current,
               start_time: "09:00", end_time: "11:00")
      end
      let!(:item_today_1h) do
        create(:task_item, task: task_today, work_date: Date.current,
               start_time: "14:00", end_time: "15:00")
      end
      let!(:item_yesterday) do
        create(:task_item, task: task_yesterday, work_date: Date.current - 1.day,
               start_time: "10:00", end_time: "12:00")
      end

      before { get root_path }

      # AC: assigns existem no controller
      it "atribui @daily_task_count" do
        expect(controller.instance_variable_get(:@daily_task_count)).not_to be_nil
      end

      it "atribui @monthly_task_count" do
        expect(controller.instance_variable_get(:@monthly_task_count)).not_to be_nil
      end

      it "atribui @daily_value" do
        expect(controller.instance_variable_get(:@daily_value)).not_to be_nil
      end

      # AC: KPI 5 — Qtde Tasks Hoje conta apenas tasks com work_date = today
      it "AC KPI5: @daily_task_count conta somente tasks com task_items de hoje" do
        expect(controller.instance_variable_get(:@daily_task_count)).to eq(1)
      end

      # AC: KPI 4 — Qtde Tasks Mês conta tasks com task_items no mês (distinct)
      it "AC KPI4: @monthly_task_count conta tasks com task_items no mês corrente" do
        expect(controller.instance_variable_get(:@monthly_task_count)).to eq(2)
      end

      # AC: KPI 6 — Valor Hoje = hours_worked de hoje * hourly_rate
      it "AC KPI6: @daily_value soma hours_worked de hoje * hourly_rate" do
        # item_today_2h (2h) + item_today_1h (1h) = 3h * R$100 = R$300
        expect(controller.instance_variable_get(:@daily_value)).to eq(300.0)
      end

      it "retorna HTTP 200" do
        expect(response).to have_http_status(:ok)
      end

      # AC: KPI5 — task_items de ontem NÃO contam como "hoje"
      it "AC KPI5: task_items de dias anteriores não entram na contagem de hoje" do
        count = controller.instance_variable_get(:@daily_task_count)
        # task_yesterday tem item_yesterday (ontem), não deve ser contada
        expect(count).to eq(1)
      end

      # AC: KPI6 — Valor de ontem não entra no Valor Hoje
      it "AC KPI6: task_items de ontem não entram no Valor Hoje" do
        value = controller.instance_variable_get(:@daily_value)
        # item_yesterday é 2h * 100 = 200, não deve somar
        expect(value).to eq(300.0)
      end
    end

    context "sem task_items" do
      before { get root_path }

      it "AC KPI4: @monthly_task_count = 0 sem task_items" do
        expect(controller.instance_variable_get(:@monthly_task_count)).to eq(0)
      end

      it "AC KPI5: @daily_task_count = 0 sem task_items" do
        expect(controller.instance_variable_get(:@daily_task_count)).to eq(0)
      end

      it "AC KPI6: @daily_value = 0 sem task_items" do
        expect(controller.instance_variable_get(:@daily_value)).to eq(0)
      end
    end

    context "com task_items apenas de outros meses" do
      let!(:task_old) do
        create(:task, company: company, project: project,
               start_date: Date.current.beginning_of_month - 1.month)
      end
      let!(:item_old) do
        create(:task_item, task: task_old,
               work_date: Date.current.beginning_of_month - 1.month)
      end

      before { get root_path }

      it "AC KPI4: @monthly_task_count = 0 para task_items de outros meses" do
        expect(controller.instance_variable_get(:@monthly_task_count)).to eq(0)
      end

      it "AC KPI5: @daily_task_count = 0 para task_items de outros dias" do
        expect(controller.instance_variable_get(:@daily_task_count)).to eq(0)
      end

      it "AC KPI6: @daily_value = 0 para task_items de outros dias" do
        expect(controller.instance_variable_get(:@daily_value)).to eq(0)
      end
    end

    # AC: Layout — 6 cards no grid
    context "renderização dos 6 KPI cards" do
      before { get root_path }

      it "exibe o card Horas Hoje" do
        expect(response.body).to include("Horas Hoje")
      end

      it "exibe o card Horas Mês" do
        expect(response.body).to include("Horas Mês")
      end

      it "exibe o card Valor Mês" do
        expect(response.body).to include("Valor Mês")
      end

      it "exibe o card Tasks Mês" do
        expect(response.body).to include("Tasks Mês")
      end

      it "exibe o card Tasks Hoje" do
        expect(response.body).to include("Tasks Hoje")
      end

      it "exibe o card Valor Hoje" do
        expect(response.body).to include("Valor Hoje")
      end
    end
  end
end
