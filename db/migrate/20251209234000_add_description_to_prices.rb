# frozen_string_literal: true

class AddDescriptionToPrices < ActiveRecord::Migration[8.0]
  def change
    add_column :prices, :description, :text
  end
end
