# frozen_string_literal: true

class AddConfirmedAtToBulletins < ActiveRecord::Migration[8.1]
  def change
    add_column :bulletins, :confirmed_at, :datetime
  end
end
