# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email           :string           not null
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  google_uid      :string
#  name            :string
#  avatar_url      :string
#
# Indexes
#
#  index_users_on_email       (email) UNIQUE
#  index_users_on_google_uid  (google_uid) UNIQUE
#

require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires an email" do
      user = User.new(password: "password123")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("não pode ficar em branco")
    end

    it "requires a unique email" do
      User.create!(email: "test@example.com", password: "password123")
      user = User.new(email: "test@example.com", password: "password456")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("já está em uso")
    end

    it "requires a valid email format" do
      user = User.new(email: "invalid-email", password: "password123")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("não é válido")
    end

    it "normalizes email to lowercase" do
      user = User.create!(email: "Test@Example.COM", password: "password123")
      expect(user.email).to eq("test@example.com")
    end

    it "enforces uniqueness on google_uid when present" do
      User.create!(email: "a@example.com", google_uid: "uid-1")
      user = User.new(email: "b@example.com", google_uid: "uid-1")
      expect(user).not_to be_valid
      expect(user.errors[:google_uid]).to be_present
    end

    it "allows multiple users without google_uid" do
      User.create!(email: "a@example.com", password: "password123")
      user = User.new(email: "b@example.com", password: "password123")
      expect(user).to be_valid
    end
  end

  describe "associations" do
    it "has many sessions" do
      association = User.reflect_on_association(:sessions)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "password" do
    it "is required for new records without google_uid" do
      user = User.new(email: "test@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "is NOT required for new records with google_uid (OAuth user)" do
      user = User.new(email: "oauth@example.com", google_uid: "uid-99", name: "OAuth User")
      expect(user).to be_valid
    end

    it "is encrypted with has_secure_password" do
      user = User.create!(email: "test@example.com", password: "password123")
      expect(user.password_digest).not_to be_nil
      expect(user.password_digest).not_to eq("password123")
    end

    it "authenticates with correct password" do
      user = User.create!(email: "test@example.com", password: "password123")
      expect(user.authenticate("password123")).to eq(user)
    end

    it "fails authentication with wrong password" do
      user = User.create!(email: "test@example.com", password: "password123")
      expect(user.authenticate("wrong")).to be_falsey
    end

    it "rejects passwords shorter than 8 characters" do
      user = User.new(email: "short@example.com", password: "abc")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "rejects mismatched password_confirmation when present" do
      user = User.new(email: "mm@example.com", password: "password123", password_confirmation: "different")
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to be_present
    end
  end

  describe ".from_google_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "google-uid-123",
        info: OmniAuth::AuthHash::InfoHash.new(
          email: "newuser@example.com",
          name: "New User",
          image: "https://lh3.googleusercontent.com/a/avatar.png"
        )
      )
    end

    context "when no user exists with that google_uid or email" do
      it "creates a new user without password_digest" do
        expect {
          User.from_google_omniauth(auth)
        }.to change(User, :count).by(1)

        user = User.find_by(google_uid: "google-uid-123")
        expect(user.email).to eq("newuser@example.com")
        expect(user.name).to eq("New User")
        expect(user.avatar_url).to eq("https://lh3.googleusercontent.com/a/avatar.png")
        expect(user.password_digest).to be_nil
      end

      it "returns the persisted user" do
        user = User.from_google_omniauth(auth)
        expect(user).to be_persisted
      end
    end

    context "when a user with that google_uid already exists" do
      let!(:existing) do
        User.create!(
          email: "old@example.com",
          google_uid: "google-uid-123",
          name: "Old Name",
          avatar_url: "old.png"
        )
      end

      it "does not create a new user" do
        expect {
          User.from_google_omniauth(auth)
        }.not_to change(User, :count)
      end

      it "updates email, name and avatar from the auth payload" do
        User.from_google_omniauth(auth)
        existing.reload
        expect(existing.email).to eq("newuser@example.com")
        expect(existing.name).to eq("New User")
        expect(existing.avatar_url).to eq("https://lh3.googleusercontent.com/a/avatar.png")
      end

      it "preserves the user id (foreign key safety — AC6.2)" do
        original_id = existing.id
        User.from_google_omniauth(auth)
        existing.reload
        expect(existing.id).to eq(original_id)
      end
    end

    context "when a user already exists by email but without google_uid (admin case)" do
      let!(:admin) do
        User.create!(
          email: "newuser@example.com",
          password: "supersecret",
          password_confirmation: "supersecret"
        )
      end

      it "does not create a new user" do
        expect {
          User.from_google_omniauth(auth)
        }.not_to change(User, :count)
      end

      it "links google_uid to the existing user and preserves password_digest" do
        original_digest = admin.password_digest
        User.from_google_omniauth(auth)
        admin.reload
        expect(admin.google_uid).to eq("google-uid-123")
        expect(admin.name).to eq("New User")
        expect(admin.password_digest).to eq(original_digest)
      end

      it "preserves the admin id (AC6.2 — FK safety)" do
        original_id = admin.id
        User.from_google_omniauth(auth)
        admin.reload
        expect(admin.id).to eq(original_id)
      end

      it "still authenticates with the original password" do
        User.from_google_omniauth(auth)
        admin.reload
        expect(admin.authenticate("supersecret")).to eq(admin)
      end
    end

    context "QA finding #1 CRITICAL — payload sem email ou uid" do
      it "raises OauthInvalidPayloadError when email is nil" do
        auth.info.email = nil
        expect {
          User.from_google_omniauth(auth)
        }.to raise_error(User::OauthInvalidPayloadError, /sem email/)
      end

      it "raises OauthInvalidPayloadError when email is blank" do
        auth.info.email = "  "
        expect {
          User.from_google_omniauth(auth)
        }.to raise_error(User::OauthInvalidPayloadError)
      end

      it "raises OauthInvalidPayloadError when uid is nil" do
        auth_no_uid = OmniAuth::AuthHash.new(
          provider: "google_oauth2",
          uid: nil,
          info: OmniAuth::AuthHash::InfoHash.new(email: "x@example.com", name: "x")
        )
        expect {
          User.from_google_omniauth(auth_no_uid)
        }.to raise_error(User::OauthInvalidPayloadError, /sem email ou uid/)
      end

      it "does not create or modify any user when payload is invalid" do
        existing = User.create!(email: nil_user_email = "victim@example.com", password: "password123")
        auth.info.email = nil
        expect {
          begin
            User.from_google_omniauth(auth)
          rescue User::OauthInvalidPayloadError
            nil
          end
        }.not_to change(User, :count)
        existing.reload
        expect(existing.google_uid).to be_nil
        expect(existing.email).to eq(nil_user_email)
      end
    end

    context "QA finding #3 HIGH — email do Google conflita com outro user" do
      let!(:user_a) do
        User.create!(email: "a@example.com", google_uid: "google-uid-123", name: "User A")
      end
      let!(:user_b) do
        User.create!(email: "b@example.com", password: "password123")
      end

      it "does not overwrite email when incoming email is taken by another user" do
        auth.info.email = "b@example.com"  # email do user_b
        User.from_google_omniauth(auth)
        user_a.reload
        expect(user_a.email).to eq("a@example.com")  # preservado
        expect(user_a.google_uid).to eq("google-uid-123")
        expect(user_a.name).to eq("New User")  # name/avatar atualizam
      end

      it "still updates email when there is no conflict" do
        auth.info.email = "novo@example.com"
        User.from_google_omniauth(auth)
        user_a.reload
        expect(user_a.email).to eq("novo@example.com")
      end
    end

    context "QA finding #2 HIGH — race condition RecordNotUnique" do
      it "retries once after RecordNotUnique and succeeds on the retry" do
        # Simula concorrência: antes do save! da primeira tentativa, outro processo
        # criou o registro com o mesmo google_uid. save! viola unique e levanta RecordNotUnique.
        # O retry encontra o registro existente via find_by(google_uid:) e atualiza.
        raised_once = false
        original_save = User.instance_method(:save!)
        allow_any_instance_of(User).to receive(:save!) do |instance|
          if !raised_once
            raised_once = true
            User.create!(email: auth.info.email, google_uid: auth.uid, name: "Race")
            raise ActiveRecord::RecordNotUnique, "duplicate key value"
          else
            original_save.bind_call(instance)
          end
        end

        user = User.from_google_omniauth(auth)
        expect(user).to be_persisted
        expect(user.google_uid).to eq(auth.uid)
        expect(raised_once).to be(true)
      end

      it "re-raises RecordNotUnique after second retry fails" do
        allow_any_instance_of(User).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique, "permanent conflict")
        expect {
          User.from_google_omniauth(auth)
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe "#password_reset_token" do
    it "returns a token string" do
      user = User.create!(email: "reset@example.com", password: "password123")
      expect(user.password_reset_token).to be_a(String)
      expect(user.password_reset_token).not_to be_empty
    end
  end

  describe "#password_reset_token_expires_in" do
    it "returns a time 15 minutes in the future" do
      user = User.create!(email: "reset@example.com", password: "password123")
      expect(user.password_reset_token_expires_in).to be_within(2.seconds).of(15.minutes.from_now)
    end
  end
end
