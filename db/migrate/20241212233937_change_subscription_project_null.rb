class ChangeSubscriptionProjectNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :subscriptions, :project_id, false
  end
end
