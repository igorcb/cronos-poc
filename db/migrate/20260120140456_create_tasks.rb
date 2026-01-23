class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks, if_not_exists: true do |t|
      t.string :name, null: false
      t.references :company, null: false, foreign_key: true, if_not_exists: true
      t.references :project, null: false, foreign_key: true, if_not_exists: true
      t.date :start_date, null: false
      t.date :end_date
      t.string :status, null: false, default: 'pending'
      t.date :delivery_date
      t.decimal :estimated_hours, precision: 10, scale: 2, null: false
      t.decimal :validated_hours, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :tasks, :company_id, if_not_exists: true
    add_index :tasks, :project_id, if_not_exists: true
    add_index :tasks, :status, if_not_exists: true
    add_index :tasks, [ :company_id, :project_id ], if_not_exists: true
  end
end
