# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :subscriber, class_name: 'User', inverse_of: :subscriptions_subscribed, optional: true
  belongs_to :redeemer, class_name: 'User', inverse_of: :subscriptions_redeemed, optional: true
  belongs_to :tile, optional: true
  belongs_to :project

  has_many :redemption_invites, dependent: :restrict_with_exception

  validates :stripe_id,
            format: { with: /\Asub_[0-9a-zA-Z]+\z/, message: 'must start with sub_' },
            uniqueness: true
  validates :stripe_status, presence: true

  # https://stripe.com/docs/api/subscriptions/object#subscription_object-status
  enum :stripe_status,
       { active: 0, past_due: 1, unpaid: 2, canceled: 3, incomplete: 4, incomplete_expired: 5, trialing: 6, paused: 7 },
       prefix: :stripe_status

  enum :recurring_interval, { month: 0, year: 1 }, prefix: :recurring_interval

  # Entitles the holder to a tile (see #usable_stripe_status?). past_due is included as a grace period
  # while Stripe retries a failed payment.
  scope :usable, -> { where(stripe_status: %i[active trialing past_due]) }

  # Usable subscriptions that the user pays for or redeems: the single rule for who may view posts
  scope :viewable_by, ->(user) { usable.where(subscriber_id: user.id).or(usable.where(redeemer_id: user.id)) }

  # TODO: Migrate to prices table (subscription.price.amount_display)
  monetize :price_pence, as: :price, numericality: { greater_than: 0 }, allow_nil: true

  before_destroy :wipe_latest_subscription
  after_save :reset_tile_latest_subscription

  EXTERNALLY_PAID_PREFIX = 'sub_externallypaid'

  def reset_tile_latest_subscription
    tile&.reset_latest_subscription!
  end

  def wipe_latest_subscription
    return unless tile&.latest_subscription == self

    tile.update!(latest_subscription: nil)
  end

  def redeemed?
    redeemer_id.present?
  end

  def redeemed_by?(user)
    redeemed? && redeemer == user
  end

  def subscribed?
    subscriber_id.present?
  end

  def subscribed_by?(user)
    subscribed? && subscriber == user
  end

  def stripe_status_readable
    stripe_status.to_s.humanize.downcase.gsub('canceled', 'cancelled')
  end

  def usable_stripe_status?
    stripe_status_active? || stripe_status_trialing? || stripe_status_past_due?
  end

  # Instance form of the .viewable_by scope
  def viewable_by?(user)
    usable_stripe_status? && (subscribed_by?(user) || redeemed_by?(user))
  end

  class << self
    # The users who can view posts through the subscriptions in this relation, as a User relation
    def viewers
      usable_subscriptions = usable
      User.where(id: usable_subscriptions.select(:subscriber_id)).or(User.where(id: usable_subscriptions.select(:redeemer_id)))
    end
  end
end
