# frozen_string_literal: true

class AddBulletinEmailsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bulletin_emails, :boolean, default: true, null: false
  end
end
