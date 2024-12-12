class AddProjectToSubscription < ActiveRecord::Migration[7.2]
  def change
    add_reference :subscriptions, :project, null: true, foreign_key: true
  end
end
