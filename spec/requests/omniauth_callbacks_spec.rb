require 'rails_helper'

RSpec.describe "OmniauthCallbacks", type: :request do
  # QA finding #9 MEDIUM — around com ensure restaura logger e config corretamente.
  # QA finding #8 MEDIUM — usar delete em vez de = nil para limpar mock_auth.
  around do |example|
    original_logger = OmniAuth.config.logger
    OmniAuth.config.test_mode = true
    OmniAuth.config.logger = Logger.new(IO::NULL)
    example.run
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.logger = original_logger
    OmniAuth.config.mock_auth.delete(:google_oauth2)
  end

  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-uid-abc",
      info: OmniAuth::AuthHash::InfoHash.new(
        email: "callback@example.com",
        name: "Callback User",
        image: "https://lh3.googleusercontent.com/a/avatar.png"
      )
    )
  end

  describe "GET /auth/google_oauth2/callback (success)" do
    before do
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
    end

    it "creates a new user from the Google auth payload" do
      expect {
        get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
      }.to change(User, :count).by(1)

      user = User.find_by(google_uid: "google-uid-abc")
      expect(user.email).to eq("callback@example.com")
      expect(user.name).to eq("Callback User")
    end

    it "starts a new session and redirects to root" do
      expect {
        get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
      }.to change(Session, :count).by(1)

      expect(response).to redirect_to(root_url)
      expect(response.cookies["session_id"]).not_to be_nil
    end

    it "sets a flash notice with the user name" do
      get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
      expect(flash[:notice]).to include("Bem-vindo")
      expect(flash[:notice]).to include("Callback User")
    end

    it "falls back to email in the flash when name is blank" do
      auth_hash.info.name = nil
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
      get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
      expect(flash[:notice]).to include("callback@example.com")
    end
  end

  describe "QA finding #12 MEDIUM — rescue específico por tipo de erro" do
    before do
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
    end

    it "redirects with payload-incompleto message when OauthInvalidPayloadError" do
      allow(User).to receive(:from_google_omniauth).and_raise(User::OauthInvalidPayloadError.new("sem email"))
      get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Dados do Google incompletos. Tente novamente.")
    end

    it "redirects with vínculo-falhou message when RecordInvalid" do
      invalid_user = User.new
      invalid_user.errors.add(:email, "is invalid")
      allow(User).to receive(:from_google_omniauth).and_raise(ActiveRecord::RecordInvalid.new(invalid_user))
      get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Não foi possível vincular sua conta Google.")
    end

    it "redirects with conflict message when RecordNotUnique" do
      allow(User).to receive(:from_google_omniauth).and_raise(ActiveRecord::RecordNotUnique.new("dup key"))
      get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Conta já vinculada. Tente novamente.")
    end

    it "does NOT swallow unexpected errors (NoMethodError sobe para Rails)" do
      allow(User).to receive(:from_google_omniauth).and_raise(NoMethodError.new("undefined method"))
      expect {
        get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
      }.to raise_error(NoMethodError)
    end
  end

  describe "GET /auth/failure" do
    it "redirects to login with alert and logs the failure message" do
      expect(Rails.logger).to receive(:warn).with(/OAuth failure/)
      get "/auth/failure", params: { message: "invalid_credentials" }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Falha ao autenticar com Google.")
    end
  end

  # QA finding #6 HIGH — AC5.1 logout funciona para user OAuth sem password_digest.
  describe "DELETE /session (AC5.1 — logout para user OAuth)" do
    before do
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
    end

    it "destroys session for OAuth-only user (sem password_digest)" do
      get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
      expect(Session.count).to eq(1)
      oauth_user = User.find_by(google_uid: "google-uid-abc")
      expect(oauth_user.password_digest).to be_nil

      delete session_path
      expect(Session.count).to eq(0)
      expect(response).to redirect_to(new_session_path)
    end
  end
end
