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
       %i[active past_due unpaid canceled incomplete incomplete_expired trialing],
       prefix: :stripe_status

  enum :recurring_interval, %i[month year], prefix: :recurring_interval

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
end
