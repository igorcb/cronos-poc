require "rails_helper"

# Story 9.2 — DM-008 + QA #2, #16, #17:
# - Stream assinado por user via `[user, :dashboard]` (não string previsível).
# - Current.reset garantido após broadcast (mesmo em exception).
# - Specs verificam Current.user durante e após broadcast (não só locals).
RSpec.describe DashboardBroadcastJob, type: :job do
  let!(:user) { create(:user) }

  describe "broadcast multi-tenant" do
    it "faz broadcast no stream assinado [user, :dashboard]" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_render_to).with(
        [ user, :dashboard ],
        hash_including(partial: "dashboard/broadcast_streams")
      )
      described_class.perform_now(user.id)
    end

    it "faz broadcast no stream legado quando user_id é nil (fallback)" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_render_to).with(
        "dashboard",
        hash_including(partial: "dashboard/broadcast_streams")
      )
      described_class.perform_now(nil)
    end

    it "usa zeros como locals quando user_id é nil" do
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to) do |_, opts|
        expect(opts[:locals][:daily_hours]).to eq(0)
        expect(opts[:locals][:tasks]).to eq(Task.none)
      end
      described_class.perform_now(nil)
    end

    it "ignora user_id inexistente, sem raise (degradação suave)" do
      expect {
        described_class.perform_now(-1)
      }.not_to raise_error
    end
  end

  describe "Current.user lifecycle (QA #16, #17)" do
    it "seta Current.user durante o broadcast" do
      observed_user_id = nil
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to) do |*|
        observed_user_id = Current.user&.id
      end
      described_class.perform_now(user.id)
      expect(observed_user_id).to eq(user.id)
    end

    it "reseta Current após o broadcast (evita pollution entre jobs SolidQueue)" do
      described_class.perform_now(user.id)
      expect(Current.user).to be_nil
      expect(Current.user_override).to be_nil
    end

    it "Current.user é nil quando user_id é nil" do
      observed = :unset
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to) do |*|
        observed = Current.user
      end
      described_class.perform_now(nil)
      expect(observed).to be_nil
    end

    it "reseta Current mesmo se broadcast levantar exception" do
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to).and_raise(StandardError, "boom")
      expect {
        described_class.perform_now(user.id)
      }.to raise_error(StandardError, "boom")
      expect(Current.user).to be_nil
      expect(Current.user_override).to be_nil
    end

    it "sequência de jobs (user A → user B) não vaza tenant" do
      user_b = create(:user)
      observed_seq = []
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to) do |*|
        observed_seq << Current.user&.id
      end
      described_class.perform_now(user.id)
      described_class.perform_now(user_b.id)
      expect(observed_seq).to eq([ user.id, user_b.id ])
    end
  end
end
