# frozen_string_literal: true

class CreateBulletins < ActiveRecord::Migration[8.1]
  def change
    create_table :bulletins do |t|
      t.string :subject, null: false
      t.text :intro
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
