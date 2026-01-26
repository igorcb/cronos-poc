# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  created_at      :datetime         not null
#  email           :string           not null
#  password_digest :string           not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "Password123!" }
    password_confirmation { "Password123!" }
  end
end
