# frozen_string_literal: true

class AddReferrerToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :referrer, null: true, foreign_key: { to_table: :users }
  end
end
