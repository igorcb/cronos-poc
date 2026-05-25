class EnforceUserIdNotNullOnTenantTables < ActiveRecord::Migration[8.0]
  def up
    change_column_null :companies,  :user_id, false
    change_column_null :projects,   :user_id, false
    change_column_null :tasks,      :user_id, false
    change_column_null :task_items, :user_id, false
  end

  def down
    change_column_null :companies,  :user_id, true
    change_column_null :projects,   :user_id, true
    change_column_null :tasks,      :user_id, true
    change_column_null :task_items, :user_id, true
  end
end
