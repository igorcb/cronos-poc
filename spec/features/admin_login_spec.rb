require 'rails_helper'

RSpec.describe "Admin Login Flow", type: :feature do
  before do
    # Simulate seeded admin user
    ENV['ADMIN_EMAIL'] = 'admin@cronos-poc.local'
    ENV['ADMIN_PASSWORD'] = 'password123'

    User.find_or_create_by!(email: ENV['ADMIN_EMAIL']) do |u|
      u.password = ENV['ADMIN_PASSWORD']
      u.password_confirmation = ENV['ADMIN_PASSWORD']
    end
  end

  it "allows admin to login with seeded credentials and redirects to root" do
    visit new_session_path

    fill_in "email", with: "admin@cronos-poc.local"
    fill_in "password", with: "password123"
    click_button "Entrar"

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Dashboard")
  end

  it "maintains session after login" do
    visit new_session_path

    fill_in "email", with: "admin@cronos-poc.local"
    fill_in "password", with: "password123"
    click_button "Entrar"

    # Navigate to another page
    visit root_path

    # Should still be authenticated (not redirected to login)
    expect(page).to have_current_path(root_path)
    expect(page).not_to have_content("Digite seu email")
  end
end
