class CreateTaskItems < ActiveRecord::Migration[8.1]
  def change
    create_table :task_items, if_not_exists: true do |t|
      t.references :task, null: false, foreign_key: true, if_not_exists: true
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.decimal :hours_worked, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: 'pending'
      t.timestamps
    end

    add_index :task_items, :task_id, if_not_exists: true
    add_index :task_items, :status, if_not_exists: true
    add_index :task_items, [:task_id, :created_at], if_not_exists: true
  end
end
