require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }
  let(:session) { Session.create!(user: user, token: SecureRandom.hex, ip_address: "127.0.0.1", user_agent: "test") }

  context "with a valid session cookie" do
    it "identifies the connection by current_user" do
      cookies.signed[:session_id] = session.id
      connect "/cable"
      expect(connection.current_user).to eq(user)
    end
  end

  context "without a session cookie" do
    it "rejects the connection" do
      expect { connect "/cable" }.to have_rejected_connection
    end
  end

  context "with an invalid session cookie" do
    it "rejects the connection" do
      cookies.signed[:session_id] = -1
      expect { connect "/cable" }.to have_rejected_connection
    end
  end
end
