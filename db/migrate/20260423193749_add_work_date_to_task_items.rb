class AddWorkDateToTaskItems < ActiveRecord::Migration[8.1]
  def change
    add_column :task_items, :work_date, :date, default: -> { "CURRENT_DATE" }
  end
end
