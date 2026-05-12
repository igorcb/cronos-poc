# frozen_string_literal: true

class CreateSolidCableMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :solid_cable_messages, if_not_exists: true do |t|
      t.binary :channel, null: false, limit: 1024
      t.binary :payload, null: false, limit: 536870912
      t.datetime :created_at, null: false
      t.integer :channel_hash, null: false, limit: 8
    end

    add_index :solid_cable_messages, :channel
    add_index :solid_cable_messages, :channel_hash
    add_index :solid_cable_messages, :created_at
  end
end
