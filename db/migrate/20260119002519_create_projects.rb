# Foreign Keys:
#  company_id  (company_id => companies.id)
class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects, if_not_exists: true do |t|
      t.string :name, null: false
      t.references :company, null: false, foreign_key: true, if_not_exists: true

      t.timestamps
    end

    add_index :projects, :company_id, if_not_exists: true
  end
end
