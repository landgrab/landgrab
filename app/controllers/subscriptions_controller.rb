# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  RESUME_FAILED_MESSAGE = "We couldn't resume your subscription. Please add a valid payment method and try again."

  before_action :set_subscription, only: %i[cancel redeem_own show resume]

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
    args = { flow_data: { type: :payment_method_update } }
    # Return to the subscription (rather than the list) when the request came from its page
    if params[:subscription_id].present?
      subscription = current_user.associated_subscriptions.find_by_hashid!(params[:subscription_id])
      args[:return_url] = subscription_url(subscription)
    end

    redirect_to_billing_portal_session(args)
  end

  # Resumes a subscription paused at the end of a card-free trial; the subscriber should
  # have added a payment method first. See https://docs.stripe.com/billing/subscriptions/trials/free-trials#resume-a-paused-subscription
  def resume
    log_event_mixpanel('Subscriptions: Resume')

    return redirect_to @subscription, flash: { danger: 'Only the subscriber can resume this subscription' } unless @subscription.subscribed_by?(current_user)
    return redirect_to @subscription, flash: { notice: 'This subscription is not paused' } unless @subscription.stripe_status_paused?

    resume_stripe_subscription
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

  def resume_stripe_subscription
    # Starts a new billing period now, so Stripe invoices (and charges the default payment method) immediately
    Stripe::Subscription.resume(@subscription.stripe_id, billing_cycle_anchor: 'now')
    @subscription = StripeSubscriptionCreateOrRefreshJob.perform_now(@subscription.stripe_id)

    if @subscription.usable_stripe_status?
      redirect_to @subscription, flash: { success: 'Your subscription has been resumed!' }
    else
      redirect_to @subscription, flash: { danger: RESUME_FAILED_MESSAGE }
    end
  rescue Stripe::CardError, Stripe::InvalidRequestError => e
    log_error("Resume subscription error for #{@subscription.stripe_id}: #{e.message}")
    redirect_to @subscription, flash: { danger: RESUME_FAILED_MESSAGE }
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
