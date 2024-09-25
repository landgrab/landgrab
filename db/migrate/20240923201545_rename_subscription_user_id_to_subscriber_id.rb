class RenameSubscriptionUserIdToSubscriberId < ActiveRecord::Migration[7.1]
  def change
    rename_column :subscriptions, :user_id, :subscriber_id
  end
end
