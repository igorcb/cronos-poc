require 'rails_helper'

RSpec.describe Session, type: :model do
  describe "associations" do
    it "belongs to user" do
      association = Session.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "token generation" do
    it "generates a token before creation" do
      user = User.create!(email: "test@example.com", password: "password123")
      session = user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test")

      expect(session.token).not_to be_nil
      expect(session.token).to be_a(String)
      expect(session.token.length).to be > 0
    end

    it "generates unique tokens" do
      user = User.create!(email: "test@example.com", password: "password123")
      session1 = user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test")
      session2 = user.sessions.create!(ip_address: "127.0.0.2", user_agent: "Test")

      expect(session1.token).not_to eq(session2.token)
    end
  end
end
