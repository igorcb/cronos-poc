require "rails_helper"

RSpec.describe TasksController, type: :controller do
  let(:user) { create(:user) }
  let(:session) { user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1") }
  let(:company) { create(:company, hourly_rate: 100) }
  let!(:project) { create(:project, company: company) }  # Use let! to ensure creation

  before { cookies.signed[:session_id] = session.id }

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
      expect(assigns(:companies)).to eq([company])
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
          estimated_hours: 8.0,
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
              estimated_hours: 8.0
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
            estimated_hours: 8.0
          }
        }
        expect(response).to render_template(:new)
        expect(assigns(:task).errors[:project]).to be_present
      end
    end
  end

  describe "GET #projects" do
    let!(:other_company) { create(:company) }
    let!(:other_project) { create(:project, company: other_company, name: "Other Project") }

    it "requires authentication" do
      cookies.delete(:session_id)
      get :projects, format: :json
      expect(response).to redirect_to(new_session_path)
    end

    it "returns all projects when no company_id provided" do
      get :projects, format: :json
      json_response = JSON.parse(response.body)
      expect(json_response.size).to eq(0)
    end

    it "filters projects by company_id", :aggregate_failures do
      get :projects, format: :json, params: { company_id: company.id }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response.size).to eq(1)
      expect(json_response.first["id"]).to eq(project.id)
    end

    it "returns projects with id and name", :aggregate_failures do
      get :projects, format: :json, params: { company_id: company.id }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response.first).to have_key("id")
      expect(json_response.first).to have_key("name")
    end
  end
end
