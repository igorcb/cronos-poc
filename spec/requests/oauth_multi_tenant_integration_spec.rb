require 'rails_helper'

# Story 9.2 QA #22: integração OAuth (story 9.1) + multi-tenant (story 9.2).
# Garante que após login Google, o user vê APENAS seus próprios dados.
RSpec.describe "OAuth + Multi-tenant integration", type: :request do
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

  let!(:user_a) { create(:user, email: "alice@example.com", google_uid: "g-alice") }
  let!(:user_b) { create(:user, email: "bob@example.com",   google_uid: "g-bob") }
  let!(:company_a) { create(:company, name: "Empresa A", user: user_a) }
  let!(:company_b) { create(:company, name: "Empresa B", user: user_b) }

  def login_via_google(user)
    auth_hash = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: user.google_uid,
      info: OmniAuth::AuthHash::InfoHash.new(
        email: user.email,
        name: "User #{user.id}",
        image: "https://lh3.googleusercontent.com/avatar.png"
      )
    )
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
    get "/auth/google_oauth2/callback", env: { "omniauth.auth" => auth_hash }
  end

  it "user A faz login via Google e vê apenas suas companies" do
    login_via_google(user_a)
    get companies_path
    expect(response.body).to include("Empresa A")
    expect(response.body).not_to include("Empresa B")
  end

  it "user B faz login via Google e vê apenas suas companies" do
    login_via_google(user_b)
    get companies_path
    expect(response.body).to include("Empresa B")
    expect(response.body).not_to include("Empresa A")
  end

  it "user OAuth tenta acessar company de outro tenant via URL direta → 404" do
    login_via_google(user_b)
    get edit_company_path(company_a)
    expect(response).to have_http_status(:not_found)
  end

  it "user novo via OAuth (sem companies) carrega tela vazia sem vazar nada" do
    new_user_auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "g-newbie",
      info: OmniAuth::AuthHash::InfoHash.new(
        email: "newbie@example.com",
        name: "Newbie",
        image: nil
      )
    )
    OmniAuth.config.mock_auth[:google_oauth2] = new_user_auth
    expect {
      get "/auth/google_oauth2/callback", env: { "omniauth.auth" => new_user_auth }
    }.to change(User, :count).by(1)

    get companies_path
    expect(response).to have_http_status(:success)
    expect(response.body).not_to include("Empresa A")
    expect(response.body).not_to include("Empresa B")
  end
end
