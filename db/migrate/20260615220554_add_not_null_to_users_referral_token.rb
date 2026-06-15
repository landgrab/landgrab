# frozen_string_literal: true

class AddNotNullToUsersReferralToken < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :referral_token, false
  end
end
