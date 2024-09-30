class AddRedeemerIdToSubscription < ActiveRecord::Migration[7.1]
  def change
    add_reference :subscriptions, :redeemer, index: true
    add_foreign_key :subscriptions, :users, column: :redeemer_id
  end
end
