require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let!(:user) { create(:user, email: "profile@example.com", password: "password123", password_confirmation: "password123") }

  def sign_in
    post session_path, params: { email: "profile@example.com", password: "password123" }
  end

  describe "GET /profile" do
    context "when not authenticated" do
      it "redirects to login" do
        get profile_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in }

      it "returns 200 and shows the password form" do
        get profile_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Minha Conta")
        expect(response.body).to include("Nova senha")
        expect(response.body).to include("Confirmar nova senha")
      end
    end
  end

  describe "PATCH /profile" do
    context "when not authenticated" do
      it "redirects to login" do
        patch profile_path, params: { password: "newpass123", password_confirmation: "newpass123" }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in }

      context "with valid matching passwords" do
        it "updates the password and redirects to root with notice" do
          patch profile_path, params: { password: "newpassword1", password_confirmation: "newpassword1" }
          expect(response).to redirect_to(root_path)
          follow_redirect!
          expect(response.body).to include("Senha alterada com sucesso")
        end
      end

      context "when passwords do not match" do
        it "returns 422 and shows specific confirmation error" do
          patch profile_path, params: { password: "newpassword1", password_confirmation: "different123" }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("não é igual a")
        end
      end

      context "when password is shorter than 8 characters" do
        it "returns 422 and shows specific too_short error" do
          patch profile_path, params: { password: "short", password_confirmation: "short" }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("muito curto")
        end
      end

      context "when password is empty string" do
        it "redirects to root (has_secure_password ignores empty string — no change)" do
          patch profile_path, params: { password: "", password_confirmation: "" }
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end
