require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  describe "protected routes" do
    context "when not authenticated" do
      it "redirects to login page" do
        get root_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      let!(:user) { User.create!(email: "test@example.com", password: "password123") }

      before do
        post session_path, params: { email: "test@example.com", password: "password123" }
      end

      it "allows access to protected routes" do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Dashboard")
      end
    end
  end
end
