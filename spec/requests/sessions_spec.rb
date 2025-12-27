require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let!(:user) { User.create!(email: "test@example.com", password: "password123") }

  describe "GET /session/new" do
    it "displays the login form" do
      get new_session_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Digite seu email")
      expect(response.body).to include("Digite sua senha")
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      it "creates a session and redirects to root" do
        post session_path, params: { email: "test@example.com", password: "password123" }

        expect(response).to redirect_to(root_path)
        expect(response.cookies["session_id"]).not_to be_nil
      end

      it "creates a session record in database" do
        expect {
          post session_path, params: { email: "test@example.com", password: "password123" }
        }.to change(Session, :count).by(1)
      end
    end

    context "with invalid credentials" do
      it "shows error message and renders login form" do
        post session_path, params: { email: "test@example.com", password: "wrong" }

        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("Email ou senha inválidos")
      end

      it "does not create a session record" do
        expect {
          post session_path, params: { email: "test@example.com", password: "wrong" }
        }.not_to change(Session, :count)
      end
    end
  end

  describe "DELETE /session" do
    it "destroys the session and redirects to login" do
      post session_path, params: { email: "test@example.com", password: "password123" }

      expect {
        delete session_path
      }.to change(Session, :count).by(-1)

      expect(response).to redirect_to(new_session_path)
    end
  end
end
