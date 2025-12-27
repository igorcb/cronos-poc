class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, if_not_exists: true do |t|
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :email, unique: true, if_not_exists: true
  end
end
