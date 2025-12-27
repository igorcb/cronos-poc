require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  describe "GET /signup" do
    it "redirects to login page" do
      get "/signup"
      expect(response).to redirect_to(new_session_path)
    end

    it "shows flash message about disabled registration" do
      get "/signup"
      follow_redirect!
      expect(response.body).to include("Registro desabilitado")
    end
  end

  describe "POST /signup" do
    it "redirects to login page" do
      post "/signup", params: { user: { email: "test@example.com", password: "password" } }
      expect(response).to redirect_to(new_session_path)
    end

    it "shows flash message about disabled registration" do
      post "/signup", params: { user: { email: "test@example.com", password: "password" } }
      follow_redirect!
      expect(response.body).to include("Registro desabilitado")
    end
  end
end
