# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email           :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#

require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires an email" do
      user = User.new(password: "password123")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires a unique email" do
      User.create!(email: "test@example.com", password: "password123")
      user = User.new(email: "test@example.com", password: "password456")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "requires a valid email format" do
      user = User.new(email: "invalid-email", password: "password123")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "normalizes email to lowercase" do
      user = User.create!(email: "Test@Example.COM", password: "password123")
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "associations" do
    it "has many sessions" do
      association = User.reflect_on_association(:sessions)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "password" do
    it "is required" do
      user = User.new(email: "test@example.com")
      expect(user).not_to be_valid
    end

    it "is encrypted with has_secure_password" do
      user = User.create!(email: "test@example.com", password: "password123")
      expect(user.password_digest).not_to be_nil
      expect(user.password_digest).not_to eq("password123")
    end

    it "authenticates with correct password" do
      user = User.create!(email: "test@example.com", password: "password123")
      expect(user.authenticate("password123")).to eq(user)
    end

    it "fails authentication with wrong password" do
      user = User.create!(email: "test@example.com", password: "password123")
      expect(user.authenticate("wrong")).to be_falsey
    end
  end
end
