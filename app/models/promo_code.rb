# frozen_string_literal: true

class PromoCode < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :stripe_id,
            format: { with: /\Apromo_[0-9a-zA-Z]+\z/, message: 'must start with promo_' },
            uniqueness: true,
            unless: :free_trial?
  validates :stripe_id, absence: true, if: :free_trial?
  validates :free_trial_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  auto_strip_attributes :code, :stripe_id, squish: true

  # A free-trial code needs no Stripe promotion code: checkout starts a trial without
  # collecting a payment method, and pauses the subscription if none is added by the end.
  def free_trial?
    free_trial_days.present?
  end

  # Top-level Checkout Session params; card details aren't requested for free trials
  # (see https://docs.stripe.com/payments/checkout/free-trials)
  def stripe_checkout_options
    return { payment_method_collection: 'if_required' } if free_trial?

    { discounts: [{ promotion_code: stripe_id }] }
  end

  def stripe_trial_data
    return unless free_trial?

    {
      trial_period_days: free_trial_days,
      trial_settings: { end_behavior: { missing_payment_method: 'pause' } }
    }
  end
end
