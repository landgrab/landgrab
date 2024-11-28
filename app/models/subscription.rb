# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :subscriber, class_name: 'User', inverse_of: :subscriptions_subscribed, optional: true
  belongs_to :redeemer, class_name: 'User', inverse_of: :subscriptions_redeemed, optional: true
  belongs_to :tile, optional: true

  validates :stripe_id,
            format: { with: /\Asub_[0-9a-zA-Z]+\z/ },
            uniqueness: true
  validates :stripe_status, presence: true

  # https://stripe.com/docs/api/subscriptions/object#subscription_object-status
  enum :stripe_status,
       { active: 0, past_due: 1, unpaid: 2, canceled: 3, incomplete: 4, incomplete_expired: 5, trialing: 6 },
       prefix: :stripe_status

  enum :recurring_interval, { month: 0, year: 1 }, prefix: :recurring_interval

  # TODO: Migrate to prices table (subscription.price.amount_display)
  monetize :price_pence, as: :price, numericality: { greater_than: 0 }, allow_nil: true

  before_destroy :wipe_latest_subscription
  after_save :assign_latest_subscription

  EXTERNALLY_PAID_PREFIX = 'sub_externallypaid'

  def project_fallback
    Project.first
  end

  def assign_latest_subscription
    return if tile.nil?

    tile.update!(latest_subscription: tile.subscriptions.order(id: :desc).first)
  end

  def wipe_latest_subscription
    return if tile.nil? || tile.latest_subscription != self

    tile&.update!(latest_subscription: nil)
  end

  def verify_claims_hash(provided_hash)
    provided_hash.present? && ActiveSupport::SecurityUtils.secure_compare(claim_hash, provided_hash)
  end

  def redeemed?
    redeemer_id.present?
  end

  def reedemed_by?(user)
    redeemed? && redeemer == user
  end

  def subscribed?
    subscriber_id.present?
  end

  def subscribed_by?(user)
    subscribed? && subscriber == user
  end
end
