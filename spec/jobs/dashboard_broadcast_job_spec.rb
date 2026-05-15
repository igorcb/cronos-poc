require "rails_helper"

RSpec.describe DashboardBroadcastJob, type: :job do
  it "broadcasts dashboard partial to dashboard stream" do
    expect(Turbo::StreamsChannel).to receive(:broadcast_render_to).with(
      "dashboard",
      hash_including(partial: "dashboard/broadcast_streams")
    )
    described_class.perform_now
  end
end
