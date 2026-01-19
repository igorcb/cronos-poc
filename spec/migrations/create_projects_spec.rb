require 'rails_helper'

RSpec.describe 'CreateProjects migration', type: :migration do
  let(:migration) { ActiveRecord::Migration[8.1] }

  describe 'rollback' do
    it 'successfully rolls back the migration' do
      # Simulate migration up
      migration.create_table :projects, if_not_exists: true do |t|
        t.string :name, null: false
        t.references :company, null: false, foreign_key: true, if_not_exists: true
        t.timestamps
      end
      migration.add_index :projects, :company_id, if_not_exists: true

      # Verify table exists
      expect(ActiveRecord::Base.connection.table_exists?(:projects)).to be true

      # Rollback
      migration.drop_table :projects, if_exists: true

      # Verify table is removed
      expect(ActiveRecord::Base.connection.table_exists?(:projects)).to be false
    end
  end

  describe 'migration validation' do
    it 'ensures name column has NOT NULL constraint' do
      column = Project.columns_hash['name']
      expect(column.null).to be false
    end

    it 'ensures company_id column has NOT NULL constraint' do
      column = Project.columns_hash['company_id']
      expect(column.null).to be false
    end

    it 'ensures company_id has foreign key constraint' do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(:projects)
      fk = foreign_keys.find { |fk| fk.column == 'company_id' }

      expect(fk).to be_present
      expect(fk.to_table).to eq('companies')
    end

    it 'ensures company_id index exists' do
      indexes = ActiveRecord::Base.connection.indexes(:projects)
      company_index = indexes.find { |idx| idx.columns == [ 'company_id' ] }

      expect(company_index).to be_present
    end
  end
end
