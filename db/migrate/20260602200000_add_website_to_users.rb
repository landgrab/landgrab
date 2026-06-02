# frozen_string_literal: true

class AddWebsiteToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :website_url, :string
    add_column :users, :website_title, :string
  end
end
