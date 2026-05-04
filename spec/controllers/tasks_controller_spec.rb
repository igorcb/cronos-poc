require "rails_helper"

RSpec.describe TasksController, type: :controller do
  let(:user) { create(:user) }
  let(:session) { user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1") }
  let(:company) { create(:company, hourly_rate: 100) }
  let!(:project) { create(:project, company: company) }  # Use let! to ensure creation

  before { cookies.signed[:session_id] = session.id }

  describe "GET #index" do
    it "requires authentication" do
      cookies.delete(:session_id)
      get :index
      expect(response).to redirect_to(new_session_path)
    end

    it "returns success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "assigns @tasks for current month" do
      task_today = create(:task, company: company, project: project, start_date: Date.current)
      task_last_month = create(:task, company: company, project: project, start_date: 2.months.ago.to_date)
      get :index
      expect(assigns(:tasks)).to include(task_today)
      expect(assigns(:tasks)).not_to include(task_last_month)
    end

    it "assigns @daily_total as a numeric value" do
      get :index
      expect(assigns(:daily_total)).to be_a(Numeric)
    end

    it "assigns @daily_total as 0 when no TaskItems exist today" do
      get :index
      expect(assigns(:daily_total)).to eq(0)
    end

    it "assigns @daily_total with sum of hours_worked for today's task_items" do
      task_today = create(:task, company: company, project: project, start_date: Date.current)
      create(:task_item, task: task_today, start_time: "09:00", end_time: "10:30")
      create(:task_item, task: task_today, start_time: "14:00", end_time: "15:00")
      get :index
      expect(assigns(:daily_total)).to be > 0
    end

    it "does not include hours from other days in @daily_total" do
      task_yesterday = create(:task, company: company, project: project, start_date: Date.current - 1)
      create(:task_item, task: task_yesterday, start_time: "09:00", end_time: "10:30")
      get :index
      expect(assigns(:daily_total)).to eq(0)
    end

    it "assigns @company_monthly_totals" do
      get :index
      expect(assigns(:company_monthly_totals)).not_to be_nil
    end

    it "includes current month tasks in @company_monthly_totals" do
      task = create(:task, company: company, project: project, start_date: Date.current)
      create(:task_item, task: task, start_time: "09:00", end_time: "11:00")
      get :index
      sql = assigns(:company_monthly_totals).to_sql
      result = ActiveRecord::Base.connection.execute(sql)
      company_ids = result.map { |r| r["id"] }
      expect(company_ids).to include(company.id)
    end

    it "excludes tasks from other months in @company_monthly_totals" do
      task_other_month = create(:task, company: company, project: project, start_date: 2.months.ago.to_date)
      create(:task_item, task: task_other_month, start_time: "09:00", end_time: "11:00")
      get :index
      sql = assigns(:company_monthly_totals).to_sql
      result = ActiveRecord::Base.connection.execute(sql)
      company_ids = result.map { |r| r["id"] }
      expect(company_ids).not_to include(company.id)
    end

    it "assigns @companies for filter selects" do
      get :index
      expect(assigns(:companies)).to include(company)
    end

    it "assigns @projects for filter selects" do
      get :index
      expect(assigns(:projects)).to include(project)
    end

    context "com filtro de empresa" do
      let(:company1) { create(:company) }
      let(:company2) { create(:company) }
      let!(:task1) { create(:task, company: company1, project: create(:project, company: company1), start_date: Date.current) }
      let!(:task2) { create(:task, company: company2, project: create(:project, company: company2), start_date: Date.current) }

      it "filtra tasks pela empresa selecionada" do
        get :index, params: { company_id: company1.id }
        expect(assigns(:tasks)).to include(task1)
        expect(assigns(:tasks)).not_to include(task2)
      end

      it "atribui apenas projetos da empresa selecionada em @projects" do
        get :index, params: { company_id: company1.id }
        project_company_ids = assigns(:projects).map(&:company_id).uniq
        expect(project_company_ids).to eq([ company1.id ])
      end
    end

    context "com filtro de projeto" do
      let(:company_f) { create(:company) }
      let(:project1) { create(:project, company: company_f) }
      let(:project2) { create(:project, company: company_f) }
      let!(:task1) { create(:task, company: company_f, project: project1, start_date: Date.current) }
      let!(:task2) { create(:task, company: company_f, project: project2, start_date: Date.current) }

      it "filtra tasks pelo projeto selecionado" do
        get :index, params: { project_id: project1.id }
        expect(assigns(:tasks)).to include(task1)
        expect(assigns(:tasks)).not_to include(task2)
      end
    end

    context "com filtros combinados (empresa + projeto)" do
      let(:company_f) { create(:company) }
      let(:project_a) { create(:project, company: company_f) }
      let(:project_b) { create(:project, company: company_f) }
      let!(:task1) { create(:task, company: company_f, project: project_a, start_date: Date.current) }
      let!(:task2) { create(:task, company: company_f, project: project_b, start_date: Date.current) }

      it "aplica ambos os filtros simultaneamente" do
        get :index, params: { company_id: company_f.id, project_id: project_a.id }
        expect(assigns(:tasks)).to include(task1)
        expect(assigns(:tasks)).not_to include(task2)
      end
    end

    context "sem filtros" do
      it "retorna todas as tasks do mês" do
        create(:task, company: company, project: project, start_date: Date.current)
        get :index
        expect(assigns(:tasks)).to be_present
      end
    end

    context "com filtro de status" do
      let!(:task_pending)   { create(:task, :pending,   company: company, project: project, start_date: Date.current) }
      let!(:task_completed) { create(:task, :completed, company: company, project: project, start_date: Date.current) }

      it "filtra tasks pelo status selecionado" do
        get :index, params: { status: "pending" }
        expect(assigns(:tasks)).to include(task_pending)
        expect(assigns(:tasks)).not_to include(task_completed)
      end
    end

    context "com filtro de período last_7_days" do
      let!(:task_recent) { create(:task, company: company, project: project, start_date: 3.days.ago.to_date) }
      let!(:task_old)    { create(:task, company: company, project: project, start_date: 2.months.ago.to_date) }

      it "retorna apenas tasks dos últimos 7 dias" do
        get :index, params: { period: "last_7_days" }
        expect(assigns(:tasks)).to include(task_recent)
        expect(assigns(:tasks)).not_to include(task_old)
      end
    end

    context "com filtro de período personalizado" do
      let!(:task_in_range)  { create(:task, company: company, project: project, start_date: Date.new(2026, 3, 15)) }
      let!(:task_out_range) { create(:task, company: company, project: project, start_date: Date.new(2026, 1, 1)) }

      it "filtra tasks pelo range de datas informado" do
        get :index, params: { period: "custom", start_date: "2026-03-01", end_date: "2026-03-31" }
        expect(assigns(:tasks)).to include(task_in_range)
        expect(assigns(:tasks)).not_to include(task_out_range)
      end
    end

    context "com filtros combinados (status + empresa)" do
      let(:company_sc) { create(:company) }
      let!(:task1) { create(:task, :pending,   company: company_sc, project: create(:project, company: company_sc), start_date: Date.current) }
      let!(:task2) { create(:task, :completed, company: company_sc, project: create(:project, company: company_sc), start_date: Date.current) }

      it "aplica status e empresa simultaneamente" do
        get :index, params: { company_id: company_sc.id, status: "pending" }
        expect(assigns(:tasks)).to include(task1)
        expect(assigns(:tasks)).not_to include(task2)
      end
    end

    context "com filtro de período last_month" do
      let!(:task_last_month) { create(:task, company: company, project: project, start_date: 1.month.ago.to_date) }
      let!(:task_current)    { create(:task, company: company, project: project, start_date: Date.current) }

      it "retorna apenas tasks do mês anterior" do
        get :index, params: { period: "last_month" }
        expect(assigns(:tasks)).to include(task_last_month)
        expect(assigns(:tasks)).not_to include(task_current)
      end
    end

    context "com filtro de período current_week" do
      let!(:task_this_week) { create(:task, company: company, project: project, start_date: Date.current.beginning_of_week) }
      let!(:task_old)       { create(:task, company: company, project: project, start_date: 2.months.ago.to_date) }

      it "retorna apenas tasks da semana atual" do
        get :index, params: { period: "current_week" }
        expect(assigns(:tasks)).to include(task_this_week)
        expect(assigns(:tasks)).not_to include(task_old)
      end
    end

    context "com filtro de período custom com data inválida" do
      let!(:task_current) { create(:task, company: company, project: project, start_date: Date.current) }

      it "faz fallback para mês atual quando start_date é inválida" do
        get :index, params: { period: "custom", start_date: "nao-e-data", end_date: "2026-03-31" }
        expect(assigns(:tasks)).to include(task_current)
      end

      it "faz fallback para mês atual quando apenas start_date é fornecida" do
        get :index, params: { period: "custom", start_date: "2026-03-01" }
        expect(assigns(:tasks)).to include(task_current)
      end
    end

    context "com status inválido" do
      let!(:task_pending) { create(:task, :pending, company: company, project: project, start_date: Date.current) }

      it "ignora status inválido e retorna tasks do mês" do
        get :index, params: { status: "invalid_value" }
        expect(response).to have_http_status(:success)
        expect(assigns(:tasks)).to include(task_pending)
      end
    end

    context "com filtros combinados (project_id + period)" do
      let(:company_cp) { create(:company) }
      let(:project_cp) { create(:project, company: company_cp) }
      let(:project_cp2) { create(:project, company: company_cp) }
      let!(:task_in)  { create(:task, company: company_cp, project: project_cp,  start_date: 3.days.ago.to_date) }
      let!(:task_out) { create(:task, company: company_cp, project: project_cp2, start_date: 3.days.ago.to_date) }

      it "aplica project_id e period simultaneamente" do
        get :index, params: { project_id: project_cp.id, period: "last_7_days" }
        expect(assigns(:tasks)).to include(task_in)
        expect(assigns(:tasks)).not_to include(task_out)
      end
    end

    context "Story 6.3 - recalcular totalizadores conforme filtros (AC1-AC5)" do
      let(:company1) { create(:company, hourly_rate: 100) }
      let(:company2) { create(:company, hourly_rate: 200) }
      let(:proj1) { create(:project, company: company1) }
      let(:proj2) { create(:project, company: company2) }
      let!(:task1) { create(:task, company: company1, project: proj1, start_date: Date.current) }
      let!(:task2) { create(:task, company: company2, project: proj2, start_date: Date.current) }

      before do
        create(:task_item, task: task1, start_time: "09:00", end_time: "10:00")
        create(:task_item, task: task2, start_time: "11:00", end_time: "13:00")
      end

      context "AC1 - totalizadores recalculam baseados nas entradas filtradas" do
        it "daily_total reflete apenas horas das tasks da empresa filtrada" do
          get :index, params: { company_id: company1.id }
          total_with_filter = assigns(:daily_total)
          get :index
          total_without_filter = assigns(:daily_total)
          expect(total_with_filter).to be < total_without_filter
        end

        it "company_monthly_totals inclui apenas empresa filtrada" do
          get :index, params: { company_id: company1.id }
          totals = assigns(:company_monthly_totals)
          sql = totals.to_sql
          result = ActiveRecord::Base.connection.execute(sql)
          ids = result.map { |r| r["id"] }
          expect(ids).to include(company1.id)
          expect(ids).not_to include(company2.id)
        end
      end

      context "AC2 - total geral exibe soma apenas das entradas visíveis" do
        it "daily_total não inclui horas de tasks excluídas pelo filtro de projeto" do
          get :index, params: { project_id: proj1.id }
          expect(assigns(:daily_total)).to eq(60)
        end
      end

      context "AC3 - total por empresa agrupa apenas entradas filtradas" do
        it "company_monthly_totals exclui empresa sem tasks no filtro aplicado" do
          get :index, params: { company_id: company1.id }
          totals = assigns(:company_monthly_totals)
          sql = totals.to_sql
          result = ActiveRecord::Base.connection.execute(sql)
          ids = result.map { |r| r["id"] }
          expect(ids).not_to include(company2.id)
        end
      end

      context "AC5 - mensagem indica quantidade de entradas filtradas" do
        it "atribui @filtered_count com total de tasks visíveis" do
          get :index, params: { company_id: company1.id }
          expect(assigns(:filtered_count)).to eq(1)
        end

        it "atribui @is_filtered como true quando filtro de empresa está ativo" do
          get :index, params: { company_id: company1.id }
          expect(assigns(:is_filtered)).to be true
        end

        it "atribui @is_filtered como true quando filtro de projeto está ativo" do
          get :index, params: { project_id: proj1.id }
          expect(assigns(:is_filtered)).to be true
        end

        it "atribui @is_filtered como true quando filtro de status está ativo" do
          get :index, params: { status: "pending" }
          expect(assigns(:is_filtered)).to be true
        end

        it "atribui @is_filtered como true quando período não é current_month" do
          get :index, params: { period: "last_7_days" }
          expect(assigns(:is_filtered)).to be true
        end

        it "atribui @is_filtered como false sem filtros ativos" do
          get :index
          expect(assigns(:is_filtered)).to be false
        end

        it "atribui @is_filtered como false quando period é current_month (padrão)" do
          get :index, params: { period: "current_month" }
          expect(assigns(:is_filtered)).to be false
        end

        it "atribui @filtered_count igual ao total de tasks sem filtros" do
          get :index
          expect(assigns(:filtered_count)).to eq(assigns(:tasks).count)
        end

        it "atribui @filtered_count maior que zero quando há tasks filtradas" do
          get :index, params: { company_id: company1.id }
          expect(assigns(:filtered_count)).to be > 0
        end

        it "retorna sucesso com filtros ativos" do
          get :index, params: { company_id: company1.id }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context "QA fix - @is_filtered não deve ser true com company_id inválido" do
      it "atribui @is_filtered como false quando company_id é string não-numérica" do
        get :index, params: { company_id: "abc" }
        expect(assigns(:is_filtered)).to be false
      end

      it "atribui @is_filtered como false quando project_id é string não-numérica" do
        get :index, params: { project_id: "xyz" }
        expect(assigns(:is_filtered)).to be false
      end
    end

    context "QA fix - @period_label reflete o período selecionado" do
      it "retorna 'este mês' por padrão" do
        get :index
        expect(assigns(:period_label)).to eq("este mês")
      end

      it "retorna 'o mês anterior' para last_month" do
        get :index, params: { period: "last_month" }
        expect(assigns(:period_label)).to eq("o mês anterior")
      end

      it "retorna 'os últimos 7 dias' para last_7_days" do
        get :index, params: { period: "last_7_days" }
        expect(assigns(:period_label)).to eq("os últimos 7 dias")
      end

      it "retorna 'a semana atual' para current_week" do
        get :index, params: { period: "current_week" }
        expect(assigns(:period_label)).to eq("a semana atual")
      end

      it "retorna 'o período selecionado' para custom" do
        get :index, params: { period: "custom", start_date: "2026-03-01", end_date: "2026-03-31" }
        expect(assigns(:period_label)).to eq("o período selecionado")
      end
    end

    context "coerção de params para inteiro" do
      let(:company_f) { create(:company) }
      let(:project_f) { create(:project, company: company_f) }
      let!(:task_f) { create(:task, company: company_f, project: project_f, start_date: Date.current) }

      it "aceita company_id como string numérica e filtra corretamente" do
        get :index, params: { company_id: company_f.id.to_s }
        expect(assigns(:tasks)).to include(task_f)
      end

      it "ignora company_id inválido (zero após to_i)" do
        get :index, params: { company_id: "abc" }
        expect(response).to have_http_status(:success)
      end
    end

    context "@daily_total respeita filtros ativos" do
      let(:company1) { create(:company) }
      let(:company2) { create(:company) }
      let(:proj1) { create(:project, company: company1) }
      let(:proj2) { create(:project, company: company2) }
      let!(:task1) { create(:task, company: company1, project: proj1, start_date: Date.current) }
      let!(:task2) { create(:task, company: company2, project: proj2, start_date: Date.current) }

      before do
        create(:task_item, task: task1, start_time: "09:00", end_time: "10:00")
        create(:task_item, task: task2, start_time: "11:00", end_time: "13:00")
      end

      it "retorna apenas horas das tasks da empresa filtrada" do
        get :index, params: { company_id: company1.id }
        expect(assigns(:daily_total)).to be > 0
        expect(assigns(:daily_total)).to be < 180
      end
    end
  end

  describe "GET #new" do
    it "requires authentication" do
      cookies.delete(:session_id)
      get :new
      expect(response).to redirect_to(new_session_path)
    end

    it "returns success" do
      get :new
      expect(response).to have_http_status(:success)
    end

    it "assigns new Task" do
      get :new
      expect(assigns(:task)).to be_a_new(Task)
    end

    it "assigns active companies" do
      get :new
      expect(assigns(:companies)).to include(company)
    end
  end

  describe "POST #create" do
    let(:valid_params) {
      {
        task: {
          code: "20001",
          name: "Test Task",
          company_id: company.id,
          project_id: project.id,
          start_date: Date.today,
          estimated_hours_hm: "08:00",
          notes: "Test notes"
        }
      }
    }

    it "requires authentication" do
      cookies.delete(:session_id)
      post :create, params: valid_params
      expect(response).to redirect_to(new_session_path)
    end

    context "with valid params" do
      it "creates a new Task" do
        expect {
          post :create, params: valid_params
        }.to change(Task, :count).by(1)
      end

      it "sets status to pending" do
        post :create, params: valid_params
        expect(Task.last.status).to eq("pending")
      end

      it "redirects to tasks_path with notice" do
        post :create, params: valid_params
        expect(response).to redirect_to(tasks_path)
        expect(flash[:notice]).to eq("Tarefa criada com sucesso")
      end

      context "with format turbo_stream" do
        it "redirects to tasks_path" do
          post :create, params: valid_params, format: :turbo_stream
          expect(response).to redirect_to(tasks_path)
        end
      end
    end

    context "with invalid params" do
      it "does not create Task" do
        expect {
          post :create, params: { task: { name: "" } }
        }.not_to change(Task, :count)
      end

      it "renders new template with unprocessable_entity status" do
        post :create, params: { task: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end

      it "assigns companies on error" do
        post :create, params: { task: { name: "" } }
        expect(assigns(:companies)).to be_present
      end
    end

    context "when project does not belong to company" do
      let(:other_company) { create(:company) }
      let(:other_project) { create(:project, company: other_company) }

      it "does not create Task" do
        expect {
          post :create, params: {
            task: {
              name: "Invalid Task",
              company_id: company.id,
              project_id: other_project.id,
              start_date: Date.today,
              estimated_hours_hm: "08:00"
            }
          }
        }.not_to change(Task, :count)
      end

      it "renders new with error" do
        post :create, params: {
          task: {
            name: "Invalid Task",
            company_id: company.id,
            project_id: other_project.id,
            start_date: Date.today,
            estimated_hours_hm: "08:00"
          }
        }
        expect(response).to render_template(:new)
        expect(assigns(:task).errors[:project]).to be_present
      end
    end
  end

  describe "PATCH #update" do
    let!(:task) { create(:task, company: company, project: project, start_date: Date.current) }
    let(:update_params) { { id: task.id, task: { name: "Updated Task" } } }

    it "requires authentication" do
      cookies.delete(:session_id)
      patch :update, params: update_params
      expect(response).to redirect_to(new_session_path)
    end

    context "with valid params" do
      it "updates the task" do
        patch :update, params: update_params
        expect(task.reload.name).to eq("Updated Task")
      end

      it "redirects to tasks_path with notice" do
        patch :update, params: update_params
        expect(response).to redirect_to(tasks_path)
        expect(flash[:notice]).to eq("Tarefa atualizada com sucesso")
      end

      context "with format turbo_stream" do
        it "returns turbo_stream response with daily_total target" do
          patch :update, params: update_params, format: :turbo_stream
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("daily_total")
        end

        it "returns turbo_stream response with company_monthly_totals target" do
          patch :update, params: update_params, format: :turbo_stream
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("company_monthly_totals")
        end

        it "returns replace turbo_stream actions" do
          patch :update, params: update_params, format: :turbo_stream
          expect(response.body).to include("action=\"replace\"")
        end
      end
    end

    context "with invalid params" do
      it "renders edit with unprocessable_entity status" do
        patch :update, params: { id: task.id, task: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:task) { create(:task, company: company, project: project, start_date: Date.current) }

    it "requires authentication" do
      cookies.delete(:session_id)
      delete :destroy, params: { id: task.id }
      expect(response).to redirect_to(new_session_path)
    end

    it "destroys the task" do
      expect {
        delete :destroy, params: { id: task.id }
      }.to change(Task, :count).by(-1)
    end

    it "redirects to tasks_path with notice" do
      delete :destroy, params: { id: task.id }
      expect(response).to redirect_to(tasks_path)
      expect(flash[:notice]).to eq("Tarefa removida com sucesso")
    end

    context "with format turbo_stream" do
      it "returns turbo_stream response with daily_total target" do
        delete :destroy, params: { id: task.id }, format: :turbo_stream
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("daily_total")
      end

      it "returns turbo_stream response with company_monthly_totals target" do
        delete :destroy, params: { id: task.id }, format: :turbo_stream
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("company_monthly_totals")
      end

      it "returns replace turbo_stream actions" do
        delete :destroy, params: { id: task.id }, format: :turbo_stream
        expect(response.body).to include("action=\"replace\"")
      end
    end
  end
end
