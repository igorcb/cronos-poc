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
      expect(assigns(:companies)).to eq([ company ])
    end
  end

  describe "POST #create" do
    let(:valid_params) {
      {
        task: {
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

      it "redirects to root_path with notice" do
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Tarefa criada com sucesso")
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
end
