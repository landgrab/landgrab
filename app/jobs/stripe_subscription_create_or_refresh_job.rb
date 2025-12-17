# frozen_string_literal: true

class StripeSubscriptionCreateOrRefreshJob < ApplicationJob
  queue_as :default

  def perform(subscription_stripe_id)
    @subscription_stripe_id = subscription_stripe_id

    stripe_subscription # Pre-fetch from Stripe API (to minimise lock time)

    @subscription = Subscription.create_with(stripe_status: extract_status)
                                .find_or_create_by(stripe_id: @subscription_stripe_id)

    @subscription.with_lock do
      @subscription.subscriber = subscriber_user
      @subscription.redeemer ||= subscriber_user if metadata_redemption_mode_self?

      @subscription.project ||= metadata_project || Project.first
      @subscription.tile ||= metadata_tile

      @subscription.update!(
        stripe_status: extract_status,
        price_pence: extract_price_pence,
        recurring_interval: extract_recurring_interval
      )
    end

    @subscription
  end

  private

  def extract_price_pence
    unit_price = stripe_subscription.fetch(:items).fetch(:data).fetch(0).fetch(:price).fetch(:unit_amount)
    quantity = stripe_subscription.fetch(:items).fetch(:data).fetch(0).fetch(:quantity)
    unit_price * quantity
  end

  def extract_recurring_interval
    stripe_subscription.fetch(:items).fetch(:data).fetch(0).fetch(:price).fetch(:recurring).fetch(:interval)
  end

  def extract_status
    stripe_subscription.fetch(:status)
  end

  def fetch_subscription
    Stripe::Subscription.retrieve(@subscription_stripe_id).to_hash
  end

  def stripe_subscription
    @stripe_subscription ||= fetch_subscription
  end

  def subscriber_user
    @subscriber_user ||= User.find_by!(stripe_customer_id: stripe_subscription.fetch(:customer))
  end

  def subscription_metadata
    @subscription_metadata ||= stripe_subscription.fetch(:metadata)
  end

  def metadata_project
    return unless subscription_metadata.key?(:project)

    Project.find_by_hashid!(subscription_metadata.fetch(:project))
  end

  def metadata_tile
    return unless subscription_metadata.key?(:tile)

    tile = Tile.find_by_hashid!(subscription_metadata.fetch(:tile))

    # Ignore tile chosen metadata if it's since been linked to another subscription
    return if tile.unavailable?

    tile
  end

  def metadata_redemption_mode
    return unless subscription_metadata.key?(CheckoutService::REDEMPTION_MODE_KEY)

    subscription_metadata.fetch(CheckoutService::REDEMPTION_MODE_KEY)
  end

  def metadata_redemption_mode_self?
    metadata_redemption_mode == CheckoutService::REDEMPTION_MODE_SELF
  end
end
