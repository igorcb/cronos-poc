require "rails_helper"

# Story 5.10: Expandir KPIs do Dashboard — 6 Métricas Globais
RSpec.describe "Dashboard KPIs", type: :request do
  let!(:user) { User.create!(email: "dashboard_kpis@example.com", password: "password123") }
  let!(:company) { create(:company, user: user, hourly_rate: 100.00) }
  let!(:project) { create(:project, company: company, user: user) }
  # Story 9.3 — DM-008 (QA #H4): sair do onboarding via helper centralizado.
  before { complete_onboarding_for(user) }

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

      it "exibe o card Tarefas do mês" do
        expect(response.body).to include("Tarefas do mês")
      end

      it "exibe o card Tarefas hoje" do
        expect(response.body).to include("Tarefas hoje")
      end

      it "exibe o card Valor Hoje" do
        expect(response.body).to include("Valor Hoje")
      end
    end

    # Story 5.19 — Novos KPIs de Entregues
    describe "KPIs de tasks delivered (Story 5.19)" do
      context "sem tasks delivered no mês" do
        before { get root_path }

        it "AC2: @monthly_delivered_count = 0" do
          expect(controller.instance_variable_get(:@monthly_delivered_count)).to eq(0)
        end

        it "AC3: @monthly_delivered_hours = 0" do
          expect(controller.instance_variable_get(:@monthly_delivered_hours)).to eq(0)
        end

        it "AC4: @monthly_delivered_value = 0" do
          expect(controller.instance_variable_get(:@monthly_delivered_value)).to eq(0)
        end

        it "AC1: exibe o card Entregas do Mês" do
          expect(response.body).to include("Entregas do Mês")
        end

        it "AC1: exibe o card Horas Entregues" do
          expect(response.body).to include("Horas Entregues")
        end

        it "AC1: exibe o card Valor Entregue" do
          expect(response.body).to include("Valor Entregue")
        end
      end

      context "com tasks delivered no mês" do
        let!(:task_delivered) do
          create(:task, company: company, project: project, start_date: Date.current)
        end
        let!(:task_pending) do
          create(:task, company: company, project: project, start_date: Date.current)
        end

        before do
          create(:task_item, task: task_delivered, work_date: Date.current,
                 start_time: "09:00", end_time: "11:00")
          create(:task_item, task: task_pending, work_date: Date.current,
                 start_time: "14:00", end_time: "15:00")
          task_delivered.update_columns(status: "delivered")
          task_delivered.reload
          get root_path
        end

        it "AC2: @monthly_delivered_count conta apenas tasks delivered" do
          expect(controller.instance_variable_get(:@monthly_delivered_count)).to eq(1)
        end

        it "AC5: task pending não entra na contagem de delivered" do
          count = controller.instance_variable_get(:@monthly_delivered_count)
          expect(count).to eq(1)
        end

        it "AC3: @monthly_delivered_hours soma validated_hours das tasks delivered" do
          hours = controller.instance_variable_get(:@monthly_delivered_hours)
          expect(hours).to eq(task_delivered.validated_hours)
        end

        it "AC4: @monthly_delivered_value calcula valor das tasks delivered" do
          value = controller.instance_variable_get(:@monthly_delivered_value)
          expected = task_delivered.validated_hours * company.hourly_rate
          expect(value).to be_within(0.01).of(expected)
        end
      end

      context "com task delivered com múltiplos task_items no mês" do
        let!(:task_multi) do
          create(:task, company: company, project: project, start_date: Date.current)
        end

        before do
          create(:task_item, task: task_multi, work_date: Date.current,
                 start_time: "09:00", end_time: "11:00")
          create(:task_item, task: task_multi, work_date: Date.current,
                 start_time: "14:00", end_time: "16:00")
          task_multi.update_columns(status: "delivered")
          task_multi.reload
          get root_path
        end

        it "não duplica validated_hours quando há múltiplos task_items" do
          hours = controller.instance_variable_get(:@monthly_delivered_hours)
          expect(hours).to eq(task_multi.validated_hours)
        end

        it "não duplica valor quando há múltiplos task_items" do
          value = controller.instance_variable_get(:@monthly_delivered_value)
          expect(value).to be_within(0.01).of(task_multi.validated_hours * company.hourly_rate)
        end

        it "conta task apenas uma vez mesmo com múltiplos task_items" do
          expect(controller.instance_variable_get(:@monthly_delivered_count)).to eq(1)
        end
      end

      context "com tasks delivered de outros meses" do
        let!(:task_old_delivered) do
          create(:task, company: company, project: project,
                 start_date: 1.month.ago.to_date)
        end

        before do
          create(:task_item, task: task_old_delivered,
                 work_date: 1.month.ago.to_date,
                 start_time: "09:00", end_time: "11:00")
          task_old_delivered.update_columns(status: "delivered")
          get root_path
        end

        it "AC5: tasks delivered de outros meses não entram no KPI do mês atual" do
          expect(controller.instance_variable_get(:@monthly_delivered_count)).to eq(0)
        end
      end
    end

    # Story 5.20 — KPI Média por Entrega
    describe "KPI Média por Entrega (Story 5.20)" do
      context "sem tasks delivered no mês" do
        before { get root_path }

        it "AC8: @monthly_avg_per_delivery = 0 sem divisão por zero" do
          expect(controller.instance_variable_get(:@monthly_avg_per_delivery)).to eq(0)
        end

        it "AC4: exibe R$ 0,00 quando não há entregas no mês" do
          expect(response.body).to include("kpi-media-por-entrega")
          expect(response.body).to include("R$0,00")
        end

        it "AC5: exibe elemento inline ao lado do botão +" do
          expect(response.body).to include("kpi-media-por-entrega-inline")
        end
      end

      context "com uma task delivered de uma única empresa" do
        let!(:task_delivered) do
          create(:task, company: company, project: project, start_date: Date.current)
        end

        before do
          create(:task_item, task: task_delivered, work_date: Date.current,
                 start_time: "09:00", end_time: "11:00")
          task_delivered.update_columns(status: "delivered")
          task_delivered.reload
          get root_path
        end

        it "AC2: calcula média = validated_hours * hourly_rate / count" do
          avg = controller.instance_variable_get(:@monthly_avg_per_delivery)
          expected = task_delivered.validated_hours * company.hourly_rate / 1
          expect(avg).to be_within(0.01).of(expected)
        end

        it "AC1: exibe o card Média por Entrega no grid" do
          expect(response.body).to include("kpi-media-por-entrega")
        end
      end

      context "com tasks delivered de múltiplas empresas (média ponderada)" do
        let(:company2) { create(:company, hourly_rate: 200.00) }
        let(:project2) { create(:project, company: company2) }

        let!(:task_a) { create(:task, company: company,  project: project,  start_date: Date.current) }
        let!(:task_b) { create(:task, company: company2, project: project2, start_date: Date.current) }

        before do
          create(:task_item, task: task_a, work_date: Date.current, start_time: "09:00", end_time: "11:00")
          create(:task_item, task: task_b, work_date: Date.current, start_time: "14:00", end_time: "16:00")
          task_a.update_columns(status: "delivered")
          task_b.update_columns(status: "delivered")
          task_a.reload
          task_b.reload
          get root_path
        end

        it "AC3: usa média ponderada (SUM(hours*rate) / COUNT)" do
          avg = controller.instance_variable_get(:@monthly_avg_per_delivery)
          expected_value = (task_a.validated_hours * company.hourly_rate) + (task_b.validated_hours * company2.hourly_rate)
          expected_avg = expected_value / 2
          expect(avg).to be_within(0.01).of(expected_avg)
        end
      end

      context "com task delivered com múltiplos task_items (sem duplicação)" do
        let!(:task_multi) { create(:task, company: company, project: project, start_date: Date.current) }

        before do
          create(:task_item, task: task_multi, work_date: Date.current, start_time: "09:00", end_time: "11:00")
          create(:task_item, task: task_multi, work_date: Date.current, start_time: "14:00", end_time: "16:00")
          task_multi.update_columns(status: "delivered")
          task_multi.reload
          get root_path
        end

        it "não duplica valor quando task tem múltiplos task_items" do
          avg = controller.instance_variable_get(:@monthly_avg_per_delivery)
          expected = task_multi.validated_hours * company.hourly_rate / 1
          expect(avg).to be_within(0.01).of(expected)
        end
      end
    end

    # Story 13.3 — KPI "Horas sem tarefa" no Dashboard (DM-012)
    describe "KPI Horas sem tarefa (Story 13.3)" do
      context "sem IdlePeriods" do
        before { get root_path }

        it "AC3: @daily_idle_hours = 0 sem registros" do
          expect(controller.instance_variable_get(:@daily_idle_hours)).to eq(0)
        end

        it "AC3: @monthly_idle_hours = 0 sem registros" do
          expect(controller.instance_variable_get(:@monthly_idle_hours)).to eq(0)
        end

        it "AC1: exibe o card Horas sem tarefa (hoje)" do
          expect(response.body).to include("Horas sem tarefa (hoje)")
        end

        it "AC2: exibe o card Horas sem tarefa (mês)" do
          expect(response.body).to include("Horas sem tarefa (mês)")
        end
      end

      context "com IdlePeriods no dia e no mês" do
        let!(:idle_today_a) { create(:idle_period, user: user, work_date: Date.current, start_time: "09:00", end_time: "10:30") }
        let!(:idle_today_b) { create(:idle_period, user: user, work_date: Date.current, start_time: "14:00", end_time: "15:00") }
        let!(:idle_earlier_this_month) do
          create(:idle_period, user: user, work_date: Date.current.beginning_of_month, start_time: "09:00", end_time: "10:00")
        end
        let!(:idle_other_month) do
          create(:idle_period, user: user, work_date: Date.current.beginning_of_month - 1.month, start_time: "09:00", end_time: "10:00")
        end
        let!(:idle_other_user) { create(:idle_period, user: create(:user), work_date: Date.current, start_time: "09:00", end_time: "10:00") }

        before { get root_path }

        it "AC1: @daily_idle_hours soma somente os IdlePeriods do Current.user de hoje" do
          expect(controller.instance_variable_get(:@daily_idle_hours)).to eq(idle_today_a.hours + idle_today_b.hours)
        end

        it "AC2: @monthly_idle_hours soma os IdlePeriods do Current.user do mês corrente" do
          expected = idle_today_a.hours + idle_today_b.hours + idle_earlier_this_month.hours
          expect(controller.instance_variable_get(:@monthly_idle_hours)).to eq(expected)
        end
      end
    end
  end
end
