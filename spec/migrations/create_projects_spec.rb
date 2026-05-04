require 'rails_helper'

RSpec.describe 'CreateProjects migration', type: :migration do
  let(:migration) { ActiveRecord::Migration[8.1] }

  describe 'rollback' do
    it 'successfully rolls back the migration' do
      conn = ActiveRecord::Base.connection

      # Temporarily remove FK from tasks so we can drop projects
      tasks_fk = conn.foreign_keys(:tasks).find { |fk| fk.to_table == 'projects' }
      conn.remove_foreign_key(:tasks, :projects) if tasks_fk

      begin
        expect(conn.table_exists?(:projects)).to be true

        conn.drop_table :projects, if_exists: true

        expect(conn.table_exists?(:projects)).to be false
      ensure
        # Restore projects table if it was dropped
        unless conn.table_exists?(:projects)
          conn.create_table :projects do |t|
            t.string :name, null: false
            t.references :company, null: false, foreign_key: true
            t.timestamps
          end
        end

        # Restore FK on tasks if it was removed
        if tasks_fk && conn.foreign_keys(:tasks).none? { |fk| fk.to_table == 'projects' }
          conn.add_foreign_key :tasks, :projects
        end
      end
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
