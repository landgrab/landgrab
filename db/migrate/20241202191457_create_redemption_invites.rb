class CreateRedemptionInvites < ActiveRecord::Migration[7.1]
  def change
    create_table :redemption_invites do |t|
      t.belongs_to :subscription, null: false, foreign_key: true
      t.string :recipient_name
      t.string :recipient_email
      t.string :token, null: false

      t.timestamps
    end
  end
end
