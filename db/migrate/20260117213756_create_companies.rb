class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies, if_not_exists: true do |t|
      t.string :name, null: false
      t.decimal :hourly_rate, precision: 10, scale: 2, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :companies, :active, if_not_exists: true
  end
end
