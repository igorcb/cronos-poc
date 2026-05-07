class AddDeliveredValueToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :hourly_rate, :decimal, precision: 10, scale: 2
    add_column :tasks, :delivered_value, :decimal, precision: 10, scale: 2
  end
end
