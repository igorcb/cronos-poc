require "rails_helper"

RSpec.describe IdlePeriodsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:session) { user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1") }

  before { cookies.signed[:session_id] = session.id }

  describe "GET #new" do
    it "requires authentication" do
      cookies.delete(:session_id)
      get :new
      expect(response).to redirect_to(new_session_path)
    end

    it "renders the new template" do
      get :new
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end

    it "assigns a new idle_period with work_date as today" do
      get :new
      expect(assigns(:idle_period).work_date).to eq(Date.current)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      { idle_period: { start_time: "09:00", end_time: "10:30", work_date: Date.current } }
    end

    it "requires authentication" do
      cookies.delete(:session_id)
      post :create, params: valid_params
      expect(response).to redirect_to(new_session_path)
    end

    context "with valid params" do
      it "creates a new IdlePeriod scoped to Current.user" do
        expect {
          post :create, params: valid_params
        }.to change(IdlePeriod, :count).by(1)
        expect(IdlePeriod.last.user).to eq(user)
      end

      it "ignores user_id param" do
        post :create, params: { idle_period: { start_time: "09:00", end_time: "10:30", work_date: Date.current, user_id: other_user.id } }
        expect(IdlePeriod.last.user).to eq(user)
      end

      it "redirects to root_path on html format" do
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Período sem tarefa registrado")
      end

      context "with format turbo_stream" do
        it "returns turbo_stream response" do
          post :create, params: valid_params, format: :turbo_stream
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "closes the modal" do
          post :create, params: valid_params, format: :turbo_stream
          expect(response.body).to include("action=\"remove\"")
          expect(response.body).to include("target=\"modal\"")
        end
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { idle_period: { start_time: nil, end_time: nil, work_date: nil } } }

      it "does not create IdlePeriod" do
        expect {
          post :create, params: invalid_params
        }.not_to change(IdlePeriod, :count)
      end

      it "redirects with alert via html" do
        post :create, params: invalid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      context "with format turbo_stream" do
        it "returns turbo_stream response" do
          post :create, params: invalid_params, format: :turbo_stream
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "re-renders modal with errors targeting modal frame" do
          post :create, params: invalid_params, format: :turbo_stream
          expect(response.body).to include("modal")
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:idle_period) { create(:idle_period, user: user) }

    it "requires authentication" do
      cookies.delete(:session_id)
      delete :destroy, params: { id: idle_period.id }
      expect(response).to redirect_to(new_session_path)
    end

    it "destroys the idle_period" do
      expect {
        delete :destroy, params: { id: idle_period.id }
      }.to change(IdlePeriod, :count).by(-1)
    end

    it "redirects to root_path on html format" do
      delete :destroy, params: { id: idle_period.id }
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Período sem tarefa removido")
    end

    context "with format turbo_stream" do
      it "returns turbo_stream response removing the item" do
        delete :destroy, params: { id: idle_period.id }, format: :turbo_stream
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("action=\"remove\"")
      end
    end

    context "when destroy fails" do
      before { allow_any_instance_of(IdlePeriod).to receive(:destroy).and_return(false) }

      it "returns unprocessable_content on turbo_stream format" do
        delete :destroy, params: { id: idle_period.id }, format: :turbo_stream
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "redirects with alert via html" do
        delete :destroy, params: { id: idle_period.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when idle_period belongs to another user" do
      let!(:other_idle_period) { create(:idle_period, user: other_user) }

      it "returns 404 instead of destroying" do
        expect {
          delete :destroy, params: { id: other_idle_period.id }
        }.not_to change(IdlePeriod, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
