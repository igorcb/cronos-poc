# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin user for single-user system
puts "Creating admin user..."

admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@cronos-poc.local')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'password123')

user = User.find_or_initialize_by(email: admin_email)
user.password = admin_password
user.password_confirmation = admin_password
user.save!

puts "Admin user created/updated: #{user.email}"
puts "Login at: http://localhost:3000/session/new"

# Create companies
puts "\nCreating companies..."

companies = [
  { name: 'NobeSistema', hourly_rate: 45 },
  { name: 'Jedis', hourly_rate: 50 },
  { name: 'Solix Gescam', hourly_rate: 60 }
]

companies.each do |company_data|
  company = Company.find_or_initialize_by(name: company_data[:name])
  company.hourly_rate = company_data[:hourly_rate]
  company.active = true
  company.save!
  puts "  ✓ #{company.name} - R$ #{company.hourly_rate}/h"
end

puts "\nCreated #{Company.count} companies"
