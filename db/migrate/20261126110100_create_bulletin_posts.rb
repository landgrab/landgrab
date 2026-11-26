# frozen_string_literal: true

class CreateBulletinPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :bulletin_posts do |t|
      t.references :bulletin, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    add_index :bulletin_posts, %i[bulletin_id post_id], unique: true
  end
end
