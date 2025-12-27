require 'rails_helper'
require 'rake'

RSpec.describe "db:seed" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before do
    User.destroy_all
  end

  it "creates admin user with ENV credentials" do
    ENV['ADMIN_EMAIL'] = 'test_admin@example.com'
    ENV['ADMIN_PASSWORD'] = 'secure_password123'

    expect {
      Rake::Task['db:seed'].execute
    }.to change(User, :count).by(1)

    admin = User.find_by(email: 'test_admin@example.com')
    expect(admin).to be_present
    expect(admin.authenticate('secure_password123')).to eq(admin)
  end

  it "is idempotent (does not create duplicates)" do
    ENV['ADMIN_EMAIL'] = 'idempotent@example.com'
    ENV['ADMIN_PASSWORD'] = 'password'

    # Run seed twice
    Rake::Task['db:seed'].execute
    Rake::Task['db:seed'].reenable

    expect {
      Rake::Task['db:seed'].execute
    }.not_to change(User, :count)
  end

  it "uses default credentials when ENV not set" do
    ENV.delete('ADMIN_EMAIL')
    ENV.delete('ADMIN_PASSWORD')

    Rake::Task['db:seed'].execute

    admin = User.find_by(email: 'admin@cronos-poc.local')
    expect(admin).to be_present
  end
end
