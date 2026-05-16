require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user, email: "reset@example.com") }
    let(:mail) { described_class.reset(user) }

    it "sets the subject" do
      expect(mail.subject).to eq("Reset your password")
    end

    it "sends to the user email" do
      expect(mail.to).to eq([ "reset@example.com" ])
    end

    it "sends from the default address" do
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body with password reset link" do
      expect(mail.body.encoded).to include("reset your password")
    end
  end
end
