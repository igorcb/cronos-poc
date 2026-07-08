class CreateIdlePeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :idle_periods, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true, if_not_exists: true
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.date :work_date, null: false
      t.decimal :hours, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :idle_periods, :user_id, if_not_exists: true
    add_index :idle_periods, [ :user_id, :work_date ], if_not_exists: true
  end
end
