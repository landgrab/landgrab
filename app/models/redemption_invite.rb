# frozen_string_literal: true

class RedemptionInvite < ApplicationRecord
  belongs_to :subscription

  validates :recipient_name, length: { maximum: 255 }
  validates :recipient_email, email: true, length: { maximum: 255 }, allow_blank: true
  validates :token, presence: true

  auto_strip_attributes :recipient_name, :recipient_email, squish: true

  # TODO: track the 'redeemed at' date on a subscription.
  # TODO: track the occasion - birthday/wedding/anniversary/other?

  before_validation :populate_token

  def populate_token
    self.token ||= SecureRandom.base36
  end

  def verify_token(provided_token)
    provided_token.present? && ActiveSupport::SecurityUtils.secure_compare(token, provided_token)
  end
end
