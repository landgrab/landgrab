# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: %i[cancel redeem_own show]

  def index
    log_event_mixpanel('Subscriptions: Index')
    @subscriptions = current_user.associated_subscriptions.includes(:redeemer, :project, tile: :plot)
  end

  def show
    log_event_mixpanel('Subscriptions: Show')
  end

  def redeem_own
    if @subscription.redeemed?
      if @subscription.redeemed_by?(current_user)
        redirect_to @subscription, flash: { notice: 'This subscription is already linked to your account' }
      else
        redirect_to support_path, flash: { danger: 'Oh! This subscription is already connected to a different account. Have you got two accounts? Please reach out to us and we can help.' }
      end
    end

    log_event_mixpanel('Subscriptions: Redeem Own Subscription')

    @subscription.update!(redeemer: current_user)
    redirect_to @subscription, flash: { notice: "Great; we've redeemed the subscription against your account." }
  end

  def link_tile
    @subscription = Subscription.find_by_hashid!(params[:id])

    log_event_mixpanel('Subscriptions: Redeem')
    @tile = Tile.find_by_hashid!(params[:tile_hashid])

    flash = redeem_tile
    redirect_back_or_to(tile_path(@tile), flash:)
  end

  def manage_billing
    redirect_to_billing_portal_session(
      flow_data: {
        type: :payment_method_update
      }
    )
  end

  def cancel
    redirect_to_billing_portal_session(
      flow_data: {
        type: :subscription_cancel,
        subscription_cancel: {
          subscription: @subscription.stripe_id
        }
      }
    )
  end

  private

  def set_subscription
    @subscription = current_user.associated_subscriptions.find_by_hashid!(params[:id])
  end

  def subscription_params
    params.expect(subscription: [:tile_id])
  end

  def redirect_to_billing_portal_session(extra_args)
    args = {
      customer: current_user.stripe_customer_id,
      # Return URL where the customer will be redirected after they are done managing their billing
      return_url: subscriptions_url
    }.merge(extra_args)

    # Docs: https://docs.stripe.com/api/customer_portal/sessions/create
    redirect_to Stripe::BillingPortal::Session.create(args).url,
                status: :see_other,
                allow_other_host: true
  end

  def redeem_tile
    if @tile.unavailable?
      return { notice: "All good; you're already connected to this tile!" } if @tile.redeemed_by?(current_user)

      return { danger: 'Sorry, this tile has already been redeemed by someone else' }
    end

    return { danger: 'Sorry, you can only link tiles to your own subscriptions' } unless @subscription.redeemed_by?(current_user)

    return { danger: "This subscription was already linked to another tile: ///#{@subscription.tile.w3w}" } if @subscription.tile.present?

    @subscription.update!(tile: @tile)
    { notice: "Congratulations! You've connected to this tile!" }
  end
end
