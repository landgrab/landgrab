# frozen_string_literal: true

class AddFreeTrialDaysToPromoCodes < ActiveRecord::Migration[8.1]
  def change
    add_column :promo_codes, :free_trial_days, :integer
  end
end
