# == Schema Information
#
# Table name: companies
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  hourly_rate :decimal(10, 2)   not null
#  active      :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_companies_on_active  (active)
#

require 'rails_helper'

RSpec.describe Company, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      company = build(:company)
      expect(company).to be_valid
    end

    it "requires a name" do
      company = build(:company, name: nil)
      expect(company).not_to be_valid
      expect(company.errors[:name]).to include("não pode ficar em branco")
    end

    it "requires an hourly_rate" do
      company = build(:company, hourly_rate: nil)
      expect(company).not_to be_valid
      expect(company.errors[:hourly_rate]).to include("não pode ficar em branco")
    end

    it "requires hourly_rate to be greater than 0" do
      company = build(:company, hourly_rate: 0)
      expect(company).not_to be_valid
      expect(company.errors[:hourly_rate]).to include("deve ser maior que 0")
    end

    it "rejects negative hourly_rate" do
      company = build(:company, hourly_rate: -10)
      expect(company).not_to be_valid
      expect(company.errors[:hourly_rate]).to include("deve ser maior que 0")
    end

    it "accepts valid hourly_rate" do
      company = build(:company, hourly_rate: 150.50)
      expect(company).to be_valid
    end
  end

  describe "scopes" do
    let!(:active_company) { create(:company) }
    let!(:inactive_company) { create(:company, :inactive) }

    describe ".active" do
      it "returns only active companies" do
        expect(Company.active).to include(active_company)
        expect(Company.active).not_to include(inactive_company)
      end
    end

    describe ".inactive" do
      it "returns only inactive companies" do
        expect(Company.inactive).to include(inactive_company)
        expect(Company.inactive).not_to include(active_company)
      end
    end
  end

  describe "soft delete methods" do
    let(:company) { create(:company) }

    describe "#deactivate!" do
      it "sets active to false" do
        expect { company.deactivate! }.to change { company.active }.from(true).to(false)
      end

      it "persists the change to database" do
        company.deactivate!
        expect(company.reload.active).to be false
      end
    end

    describe "#activate!" do
      let(:company) { create(:company, :inactive) }

      it "sets active to true" do
        expect { company.activate! }.to change { company.active }.from(false).to(true)
      end

      it "persists the change to database" do
        company.activate!
        expect(company.reload.active).to be true
      end
    end
  end

  describe "default values" do
    it "defaults active to true" do
      company = Company.new(name: "Test", hourly_rate: 100)
      expect(company.active).to be true
    end
  end

  describe "hourly_rate precision" do
    it "stores hourly_rate as BigDecimal (not Float)" do
      company = create(:company, hourly_rate: 150.50)
      expect(company.hourly_rate).to be_a(BigDecimal)
    end

    it "maintains decimal precision" do
      company = create(:company, hourly_rate: 99.99)
      expect(company.reload.hourly_rate).to eq(BigDecimal("99.99"))
    end
  end

  describe "#destroy" do
    context "when company has no time_entries" do
      it "allows destruction" do
        company = create(:company)
        expect { company.destroy }.to change(Company, :count).by(-1)
      end
    end

    context "when company has projects" do
      it "prevents destruction due to foreign key constraint" do
        company = create(:company)
        create(:project, company: company)

        expect { company.destroy }.not_to change(Company, :count)
        expect(company.errors[:base]).to be_present
      end
    end
  end
end
