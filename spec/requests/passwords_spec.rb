require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "GET /passwords/new" do
    it "renders the new password reset form" do
      get new_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    let!(:user) { create(:user) }

    it "enqueues the reset email when user exists" do
      expect {
        post passwords_path, params: { email: user.email }
      }.to have_enqueued_mail(PasswordsMailer, :reset)
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects without sending email when user doesn't exist" do
      expect {
        post passwords_path, params: { email: "missing-#{SecureRandom.hex}@example.com" }
      }.not_to have_enqueued_mail(PasswordsMailer, :reset)
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /passwords/:token/edit" do
    let!(:user) { create(:user) }

    it "renders edit when token is valid" do
      get edit_password_path(user.password_reset_token)
      expect(response).to have_http_status(:ok)
    end

    it "redirects when token is invalid" do
      get edit_password_path("invalid-token")
      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to match(/invalid or has expired/)
    end
  end

  describe "PATCH /passwords/:token" do
    let!(:user) { create(:user) }
    let(:token) { user.password_reset_token }

    it "updates password and redirects to login" do
      patch password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
      expect(response).to redirect_to(new_session_path)
      expect(user.reload.authenticate("newpassword123")).to be_truthy
    end

    it "redirects back to edit when passwords don't match" do
      patch password_path(token), params: { password: "newpass1", password_confirmation: "different" }
      expect(response).to redirect_to(edit_password_path(token))
      expect(flash[:alert]).to match(/did not match/)
    end

    it "redirects when token is invalid" do
      patch password_path("invalid"), params: { password: "x", password_confirmation: "x" }
      expect(response).to redirect_to(new_password_path)
    end
  end
end
