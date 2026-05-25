class AddCompositeIndexesForTenantQueries < ActiveRecord::Migration[8.0]
  # Multi-tenant (story 9.2 QA #13):
  # Dashboard agrega por (user_id, work_date|start_date|active). Sem index composto,
  # Postgres faz Bitmap Index Scan + Filter — OK em DB pequeno, lento em tenant grande.
  # Estes indexes cobrem os patterns dominantes:
  #   - scoped_task_items.where(work_date: ...)
  #   - scoped_tasks.where(start_date: ...)
  #   - scoped_companies.active
  def change
    add_index :task_items, [ :user_id, :work_date ], name: "index_task_items_on_user_id_and_work_date"
    add_index :tasks,      [ :user_id, :start_date ], name: "index_tasks_on_user_id_and_start_date"
    add_index :companies,  [ :user_id, :active ], name: "index_companies_on_user_id_and_active"
  end
end
