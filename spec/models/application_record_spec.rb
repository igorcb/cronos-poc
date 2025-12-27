require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe 'configuration' do
    it 'is an abstract class' do
      expect(ApplicationRecord).to be < ActiveRecord::Base
      expect(ApplicationRecord.abstract_class).to be true
    end
  end
end
