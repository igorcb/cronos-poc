class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true, if_not_exists: true
      t.string :token, null: false
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
    add_index :sessions, :token, unique: true, if_not_exists: true
  end
end
