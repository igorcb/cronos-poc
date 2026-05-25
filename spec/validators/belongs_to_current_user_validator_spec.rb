require 'rails_helper'

# Story 9.2 QA #14: unit test isolado do BelongsToCurrentUserValidator,
# cobrindo positive + negative cases independente dos controllers.
RSpec.describe BelongsToCurrentUserValidator, type: :validator do
  let!(:user_a) { create(:user) }
  let!(:user_b) { create(:user) }
  let!(:company_a) { create(:company, user: user_a) }
  let!(:company_b) { create(:company, user: user_b) }

  # Garante que Current.user é reset entre testes (rails_helper já cuida, mas explicito).
  around(:each) do |ex|
    ex.run
  ensure
    Current.reset
  end

  describe "positive case (registro pertence ao Current.user)" do
    it "passa quando company_id aponta para company do Current.user" do
      Current.session = Session.create!(user: user_a, user_agent: "t", ip_address: "1")
      project = Project.new(name: "Projeto A", company_id: company_a.id, user: user_a)
      project.valid?
      expect(project.errors[:company_id]).to be_empty
    end
  end

  describe "negative case (registro pertence a outro user)" do
    it "falha quando company_id aponta para company de outro user" do
      Current.session = Session.create!(user: user_b, user_agent: "t", ip_address: "1")
      project = Project.new(name: "Projeto X", company_id: company_a.id, user: user_b)
      project.valid?
      expect(project.errors[:company_id]).to include("não pertence ao usuário atual")
    end

    it "falha quando project_id de uma Task aponta para project de outro user" do
      # Criar project ANTES de setar Current (senão validator dispara durante create da factory).
      project_of_a = create(:project, company: company_a)
      Current.session = Session.create!(user: user_b, user_agent: "t", ip_address: "1")
      task = Task.new(
        code: "1", name: "x", start_date: Date.current,
        estimated_hours_hm: "01:00", status: "pending",
        company: company_b, project: project_of_a, user: user_b
      )
      task.valid?
      expect(task.errors[:project_id]).to include("não pertence ao usuário atual")
    end
  end

  describe "edge cases (no-op)" do
    it "no-op fora de request (Current.user nil)" do
      project = Project.new(name: "x", company_id: company_a.id, user: user_b)
      project.valid?
      expect(project.errors[:company_id]).not_to include("não pertence ao usuário atual")
    end

    it "no-op quando valor é blank (delega para presence)" do
      Current.session = Session.create!(user: user_a, user_agent: "t", ip_address: "1")
      project = Project.new(name: "x", company_id: nil, user: user_a)
      project.valid?
      expect(project.errors[:company_id]).not_to include("não pertence ao usuário atual")
    end

    it "no-op quando registro inexistente (FK + presence cobrem)" do
      Current.session = Session.create!(user: user_a, user_agent: "t", ip_address: "1")
      project = Project.new(name: "x", company_id: 999_999_999, user: user_a)
      project.valid?
      expect(project.errors[:company_id]).not_to include("não pertence ao usuário atual")
    end
  end
end
