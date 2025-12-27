# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin user for single-user system
puts "Creating admin user..."

admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@cronos-poc.local')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'password123')

user = User.find_or_create_by!(email: admin_email) do |u|
  u.password = admin_password
  u.password_confirmation = admin_password
end

puts "Admin user created: #{user.email}"
puts "Login at: http://localhost:3000/session/new"
