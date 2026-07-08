require 'rails_helper'

# Story 9.2 QA #19: contrato de scoped_* helpers.
# Exige Current.user setado — sem ele, levanta MissingTenantError (loud failure).
RSpec.describe TenantScoped, type: :concern do
  let(:dummy_class) do
    Class.new do
      include TenantScoped
      # expor private para teste
      public :scoped_companies, :scoped_projects, :scoped_tasks, :scoped_task_items, :scoped_idle_periods
    end
  end

  let(:instance) { dummy_class.new }

  around(:each) do |ex|
    ex.run
  ensure
    Current.reset
  end

  describe "sem Current.user" do
    before { Current.reset }

    it "scoped_companies raise MissingTenantError" do
      expect { instance.scoped_companies }.to raise_error(TenantScoped::MissingTenantError, /Current\.user/)
    end

    it "scoped_projects raise MissingTenantError" do
      expect { instance.scoped_projects }.to raise_error(TenantScoped::MissingTenantError)
    end

    it "scoped_tasks raise MissingTenantError" do
      expect { instance.scoped_tasks }.to raise_error(TenantScoped::MissingTenantError)
    end

    it "scoped_task_items raise MissingTenantError" do
      expect { instance.scoped_task_items }.to raise_error(TenantScoped::MissingTenantError)
    end

    it "scoped_idle_periods raise MissingTenantError" do
      expect { instance.scoped_idle_periods }.to raise_error(TenantScoped::MissingTenantError)
    end
  end

  describe "com Current.user setado" do
    let!(:user) { create(:user) }

    before do
      Current.user_override = user
    end

    it "scoped_companies retorna a relation do user" do
      expect(instance.scoped_companies.to_sql).to include("user_id\" = #{user.id}")
    end

    it "scoped_idle_periods retorna a relation do user" do
      expect(instance.scoped_idle_periods.to_sql).to include("user_id\" = #{user.id}")
    end
  end
end
