class AddGoogleOauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :google_uid, :string
    add_column :users, :name, :string
    add_column :users, :avatar_url, :string
    add_index :users, :google_uid, unique: true

    # Permite usuários criados via OAuth sem senha local.
    # password_digest permanece — login email/senha continua funcionando.
    change_column_null :users, :password_digest, true
  end
end
