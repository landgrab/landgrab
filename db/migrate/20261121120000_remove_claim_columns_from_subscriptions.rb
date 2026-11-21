# frozen_string_literal: true

class RemoveClaimColumnsFromSubscriptions < ActiveRecord::Migration[8.1]
  def change
    remove_column :subscriptions, :claim_email, :string
    remove_column :subscriptions, :claim_hash, :string
  end
end
