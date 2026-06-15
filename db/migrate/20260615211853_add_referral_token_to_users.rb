# frozen_string_literal: true

class AddReferralTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :referral_token, :string
    add_index :users, :referral_token, unique: true
  end
end
