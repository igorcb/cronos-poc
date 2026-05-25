# == Schema Information
#
# Table name: projects
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  company_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_projects_on_company_id  (company_id)
#  index_projects_on_user_id     (user_id)
#

require 'rails_helper'

RSpec.describe Project, type: :model do
  describe "associations" do
    it { should belong_to(:company) }

    # TimeEntry will be created in Epic 4
    # it { should have_many(:time_entries).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      company = create(:company)
      project = build(:project, company: company)
      expect(project).to be_valid
    end

    it "requires a name" do
      project = build(:project, name: nil)
      expect(project).not_to be_valid
      expect(project.errors[:name]).to include("não pode ficar em branco")
    end

    it "requires a company" do
      project = build(:project, company: nil)
      expect(project).not_to be_valid
      expect(project.errors[:company]).to be_present
    end

    it "requires a company_id (implicit via belongs_to)" do
      project = Project.new(name: "Test Project", company_id: nil)
      expect(project).not_to be_valid
      expect(project.errors[:company]).to be_present
    end
  end

  describe "database schema" do
    it "has company_id foreign key" do
      expect(Project.column_names).to include("company_id")
    end

    it "has name column with not null constraint" do
      column = Project.columns_hash["name"]
      expect(column.null).to be false
    end
  end

  describe "associations behavior" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company: company) }

    it "returns associated company" do
      expect(project.company).to eq(company)
    end

    it "belongs to company" do
      expect(company.projects).to include(project)
    end
  end

  # Note: #destroy tests will be added when TimeEntry model is created in Epic 4
  # The Project model has `has_many :time_entries, dependent: :restrict_with_error`
  # which will prevent deletion when time entries exist
end
require 'rails_helper'

RSpec.describe Project, type: :model do
  # Multi-tenant (story 9.2 — DM-008): Company exige user_id.
  let!(:user) { create(:user) }
  let(:company) { Company.create!(name: 'Empresa Teste', hourly_rate: 100, user: user) }

  describe 'validations' do
    it 'permite projetos com mesmo nome em empresas diferentes' do
      company2 = Company.create!(name: 'Outra Empresa', hourly_rate: 150, user: user)

      Project.create!(name: 'Projeto Alpha', company: company, user: user)
      project2 = Project.new(name: 'Projeto Alpha', company: company2, user: user)

      expect(project2).to be_valid
    end

    it 'não permite projetos com mesmo nome na mesma empresa' do
      Project.create!(name: 'Projeto Beta', company: company, user: user)
      project2 = Project.new(name: 'Projeto Beta', company: company, user: user)

      expect(project2).not_to be_valid
      expect(project2.errors[:name]).to include('já está em uso')
    end
  end

  describe "multi-tenant immutability (story 9.2 QA #5)" do
    it "rejeita alterar user_id de Project existente (attr_readonly)" do
      other_user = create(:user)
      project = Project.create!(name: 'Imutavel', company: company, user: user)
      expect { project.user_id = other_user.id }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end
end
