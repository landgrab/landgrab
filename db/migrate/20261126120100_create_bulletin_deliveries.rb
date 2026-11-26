# frozen_string_literal: true

class CreateBulletinDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :bulletin_deliveries do |t|
      t.references :bulletin, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :email
      t.datetime :sent_at
      t.datetime :failed_at
      t.text :error

      t.timestamps
    end

    add_index :bulletin_deliveries, %i[bulletin_id user_id], unique: true
  end
end
