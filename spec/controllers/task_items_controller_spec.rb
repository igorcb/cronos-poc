require "rails_helper"

RSpec.describe TaskItemsController, type: :controller do
  let(:user) { create(:user) }
  let(:session) { user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1") }
  let(:company) { create(:company, hourly_rate: 100) }
  let(:project) { create(:project, company: company) }
  let(:task) { create(:task, company: company, project: project, start_date: Date.current) }

  before { cookies.signed[:session_id] = session.id }

  describe "POST #create" do
    let(:valid_params) do
      {
        task_id: task.id,
        task_item: { start_time: "09:00", end_time: "10:30", status: "pending" }
      }
    end

    it "requires authentication" do
      cookies.delete(:session_id)
      post :create, params: valid_params
      expect(response).to redirect_to(new_session_path)
    end

    context "with valid params" do
      it "creates a new TaskItem" do
        expect {
          post :create, params: valid_params
        }.to change(TaskItem, :count).by(1)
      end

      it "redirects to tasks_path on html format" do
        post :create, params: valid_params
        expect(response).to redirect_to(tasks_path)
        expect(flash[:notice]).to eq("Item criado com sucesso")
      end

      context "with format turbo_stream" do
        it "returns turbo_stream response" do
          post :create, params: valid_params, format: :turbo_stream
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "includes daily_total target in response" do
          post :create, params: valid_params, format: :turbo_stream
          expect(response.body).to include("daily_total")
        end

        it "includes company_monthly_totals target in response" do
          post :create, params: valid_params, format: :turbo_stream
          expect(response.body).to include("company_monthly_totals")
        end

        it "uses replace turbo_stream action" do
          post :create, params: valid_params, format: :turbo_stream
          expect(response.body).to include("action=\"replace\"")
        end
      end
    end

    context "with invalid params" do
      it "does not create TaskItem" do
        expect {
          post :create, params: { task_id: task.id, task_item: { start_time: nil, end_time: nil, status: "pending" } }
        }.not_to change(TaskItem, :count)
      end
    end
  end

  describe "PATCH #update" do
    let!(:task_item) { create(:task_item, task: task, start_time: "09:00", end_time: "10:30") }
    let(:update_params) do
      {
        task_id: task.id,
        id: task_item.id,
        task_item: { status: "completed" }
      }
    end

    it "requires authentication" do
      cookies.delete(:session_id)
      patch :update, params: update_params
      expect(response).to redirect_to(new_session_path)
    end

    context "with valid params" do
      it "updates the task_item" do
        patch :update, params: update_params
        expect(task_item.reload.status).to eq("completed")
      end

      it "redirects to tasks_path on html format" do
        patch :update, params: update_params
        expect(response).to redirect_to(tasks_path)
        expect(flash[:notice]).to eq("Item atualizado com sucesso")
      end

      context "with format turbo_stream" do
        it "returns turbo_stream response" do
          patch :update, params: update_params, format: :turbo_stream
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "includes daily_total target in response" do
          patch :update, params: update_params, format: :turbo_stream
          expect(response.body).to include("daily_total")
        end

        it "includes company_monthly_totals target in response" do
          patch :update, params: update_params, format: :turbo_stream
          expect(response.body).to include("company_monthly_totals")
        end

        it "uses replace turbo_stream action" do
          patch :update, params: update_params, format: :turbo_stream
          expect(response.body).to include("action=\"replace\"")
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:task_item) { create(:task_item, task: task, start_time: "09:00", end_time: "10:30") }

    it "requires authentication" do
      cookies.delete(:session_id)
      delete :destroy, params: { task_id: task.id, id: task_item.id }
      expect(response).to redirect_to(new_session_path)
    end

    it "destroys the task_item" do
      expect {
        delete :destroy, params: { task_id: task.id, id: task_item.id }
      }.to change(TaskItem, :count).by(-1)
    end

    it "redirects to tasks_path on html format" do
      delete :destroy, params: { task_id: task.id, id: task_item.id }
      expect(response).to redirect_to(tasks_path)
      expect(flash[:notice]).to eq("Item removido com sucesso")
    end

    context "with format turbo_stream" do
      it "returns turbo_stream response" do
        delete :destroy, params: { task_id: task.id, id: task_item.id }, format: :turbo_stream
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "includes daily_total target in response" do
        delete :destroy, params: { task_id: task.id, id: task_item.id }, format: :turbo_stream
        expect(response.body).to include("daily_total")
      end

      it "includes company_monthly_totals target in response" do
        delete :destroy, params: { task_id: task.id, id: task_item.id }, format: :turbo_stream
        expect(response.body).to include("company_monthly_totals")
      end

      it "uses replace turbo_stream action" do
        delete :destroy, params: { task_id: task.id, id: task_item.id }, format: :turbo_stream
        expect(response.body).to include("action=\"replace\"")
      end
    end
  end
end
