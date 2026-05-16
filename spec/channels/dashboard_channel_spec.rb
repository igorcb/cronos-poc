require "rails_helper"

RSpec.describe DashboardChannel, type: :channel do
  let(:user) { create(:user) }

  before { stub_connection current_user: user }

  it "subscribes and streams from dashboard" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("dashboard")
  end
end
