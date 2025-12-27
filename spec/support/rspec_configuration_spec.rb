require 'rails_helper'

RSpec.describe 'RSpec Configuration', type: :model do
  describe 'FactoryBot' do
    it 'includes FactoryBot syntax methods' do
      expect(self).to respond_to(:build)
      expect(self).to respond_to(:create)
      expect(self).to respond_to(:build_stubbed)
    end
  end

  describe 'Faker' do
    it 'generates random data' do
      name = Faker::Name.name
      email = Faker::Internet.email

      expect(name).to be_a(String)
      expect(name).not_to be_empty
      expect(email).to include('@')
    end
  end

  describe 'Shoulda Matchers' do
    it 'is configured with RSpec and Rails' do
      # This test verifies Shoulda Matchers is loaded
      # If this runs without error, the configuration is correct
      expect(Shoulda::Matchers).to be_a(Module)
    end
  end

  describe 'Database transactions' do
    it 'uses transactional fixtures' do
      # Verify use_transactional_fixtures is enabled
      expect(RSpec.configuration.use_transactional_fixtures).to be true
    end
  end
end
