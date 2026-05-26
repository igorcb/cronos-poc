require "rails_helper"

# Story 9.3 — DM-008: view helper de onboarding (delega ao PORO).
RSpec.describe OnboardingHelper, type: :helper do
  describe "#onboarding_step_path" do
    it "retorna new_company_path para :step_1" do
      expect(helper.onboarding_step_path(:step_1)).to eq(new_company_path)
    end

    it "retorna new_project_path para :step_2" do
      expect(helper.onboarding_step_path(:step_2)).to eq(new_project_path)
    end

    it "retorna new_task_path para :step_3" do
      expect(helper.onboarding_step_path(:step_3)).to eq(new_task_path)
    end

    it "levanta ArgumentError para step desconhecido (QA #M1 — loud failure)" do
      expect { helper.onboarding_step_path(:step_99) }.to raise_error(ArgumentError, /step desconhecido/)
    end
  end

  describe "#display_first_name (QA 9.3 #H5 — fallback duplo)" do
    it "usa primeiro token de name quando presente" do
      user = build_stubbed(:user, name: "Maria Souza", email: "maria@example.com")
      expect(helper.display_first_name(user)).to eq("Maria")
    end

    it "cai para o prefixo do email quando name é vazio" do
      user = build_stubbed(:user, name: "", email: "joao@example.com")
      expect(helper.display_first_name(user)).to eq("joao")
    end

    it "cai para o prefixo do email quando name é nil" do
      user = build_stubbed(:user, name: nil, email: "ana@example.com")
      expect(helper.display_first_name(user)).to eq("ana")
    end

    it "cai para 'amigo' quando name e email são vazios" do
      user = User.new(name: nil, email: "")
      expect(helper.display_first_name(user)).to eq("amigo")
    end

    it "cai para 'amigo' quando user é nil" do
      expect(helper.display_first_name(nil)).to eq("amigo")
    end

    it "ignora email sem @ e cai no prefixo (string toda)" do
      user = User.new(name: nil, email: "weird-no-at")
      expect(helper.display_first_name(user)).to eq("weird-no-at")
    end
  end
end
