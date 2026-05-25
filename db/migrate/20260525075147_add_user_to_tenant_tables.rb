class AddUserToTenantTables < ActiveRecord::Migration[8.0]
  def change
    add_reference :companies,   :user, foreign_key: true, null: true, index: true
    add_reference :projects,    :user, foreign_key: true, null: true, index: true
    add_reference :tasks,       :user, foreign_key: true, null: true, index: true
    add_reference :task_items,  :user, foreign_key: true, null: true, index: true
  end
end
