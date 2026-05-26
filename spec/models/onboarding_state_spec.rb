require "rails_helper"

# Story 9.3 — DM-008: OnboardingState (PORO).
RSpec.describe OnboardingState do
  let(:user) { User.create!(email: "onboarding_state@example.com", password: "password123") }
  subject(:state) { described_class.new(user) }

  describe "#step" do
    it "retorna :step_1 quando user não tem companies" do
      expect(state.step).to eq(:step_1)
    end

    it "retorna :step_2 quando user tem 1+ companies, 0 projects" do
      create(:company, user: user)
      expect(state.step).to eq(:step_2)
    end

    it "retorna :step_3 quando user tem 1+ projects, 0 tasks" do
      company = create(:company, user: user)
      create(:project, company: company, user: user)
      expect(state.step).to eq(:step_3)
    end

    it "retorna :completed quando user tem 1+ tasks" do
      company = create(:company, user: user)
      project = create(:project, company: company, user: user)
      create(:task, company: company, project: project, user: user)
      expect(state.step).to eq(:completed)
    end

    it "cacheia o resultado (não re-executa queries)" do
      expect(user).to receive(:tasks).once.and_return(double(exists?: false))
      expect(user).to receive(:projects).once.and_return(double(exists?: false))
      expect(user).to receive(:companies).once.and_return(double(exists?: false))

      3.times { state.step }
    end
  end

  describe "#active?" do
    it "é true em step_1" do
      expect(state.active?).to be true
    end

    it "é false em :completed" do
      company = create(:company, user: user)
      project = create(:project, company: company, user: user)
      create(:task, company: company, project: project, user: user)
      expect(state.active?).to be false
    end
  end

  describe "#step_state" do
    context "guard de step desconhecido (M1)" do
      it "levanta ArgumentError para step não mapeado" do
        expect { state.step_state(:step_99) }.to raise_error(ArgumentError, /step desconhecido/)
      end
    end

    context "quando current_step == :completed (M2)" do
      before do
        company = create(:company, user: user)
        project = create(:project, company: company, user: user)
        create(:task, company: company, project: project, user: user)
      end

      it "retorna :done para qualquer step" do
        expect(state.step_state(:step_1)).to eq(:done)
        expect(state.step_state(:step_2)).to eq(:done)
        expect(state.step_state(:step_3)).to eq(:done)
        expect(state.step_state(:completed)).to eq(:done)
      end
    end

    context "current_step == :step_2" do
      before { create(:company, user: user) }

      it "marca passos anteriores como :done" do
        expect(state.step_state(:step_1)).to eq(:done)
      end

      it "marca passo atual como :pending" do
        expect(state.step_state(:step_2)).to eq(:pending)
      end

      it "marca passos futuros como :locked" do
        expect(state.step_state(:step_3)).to eq(:locked)
      end
    end

    context "current_step == :step_1" do
      it "marca passo atual como :pending" do
        expect(state.step_state(:step_1)).to eq(:pending)
      end

      it "marca todos os futuros como :locked" do
        expect(state.step_state(:step_2)).to eq(:locked)
        expect(state.step_state(:step_3)).to eq(:locked)
      end
    end
  end
end
