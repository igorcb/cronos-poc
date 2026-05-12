class AddValueToTaskItems < ActiveRecord::Migration[8.1]
  def change
    add_column :task_items, :hourly_rate, :decimal, precision: 10, scale: 2
    add_column :task_items, :value, :decimal, precision: 10, scale: 2
  end
end
