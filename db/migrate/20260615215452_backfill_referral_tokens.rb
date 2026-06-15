# frozen_string_literal: true

class BackfillReferralTokens < ActiveRecord::Migration[8.1]
  def up
    User.where(referral_token: nil).find_each do |user|
      user.update!(referral_token: SecureRandom.base36(12))
    end
  end

  def down; end
end
