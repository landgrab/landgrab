class PopulateRedeemerForExistingSubscriptions < ActiveRecord::Migration[7.1]
  def up
    Subscription.where.not(subscriber: nil)
                .where(redeemer: nil)
                .where.not(tile: nil)
                .find_each do |subscription|
      # Assume subscription was subscribed by same user
      subscription.update(redeemer: subscription.subscriber)
    end
  end
end
