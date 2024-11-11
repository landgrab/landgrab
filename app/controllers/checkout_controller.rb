# frozen_string_literal: true

class CheckoutController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[generate claim]

  before_action :ensure_stripe_enrollment, only: %i[checkout]

  before_action :set_tile, only: %i[checkout success]
  before_action :set_price, only: %i[checkout generate]
  before_action :set_project, only: %i[success]

  # See docs/CHECKOUT.md
  def checkout
    promo_code = PromoCode.find_by!(code: params[:code]) if params[:code].present?

    @stripe_err = create_stripe_checkout(tile: @tile, promo_code:)

    log_event_mixpanel('Checkout: Checkout', { authed: user_signed_in? })
  end

  def generate
    log_event_mixpanel('Checkout: Generate', { authed: user_signed_in? })

    # Redirect to support legacy links; 'generate' is no longer supported
    redirect_to checkout_checkout_path(code: params[:code], price: params[:price], tile: params[:tile])
  end

  def claim
    log_event_mixpanel('Checkout: Claim', { authed: user_signed_in? })
  end

  def success
    log_event_mixpanel('Checkout: Success')

    session = Stripe::Checkout::Session.retrieve(params[:session_id])

    status = session.status
    unless status == 'complete'
      return redirect_to checkout_checkout_path,
                         flash: { danger: "Something went wrong; please try again or contact us for help. Ref:#{session.id}" }
    end

    customer_id = session.customer

    unless current_user.stripe_customer_id == customer_id
      raise "Stripe Customer ID mismatch: current user '#{current_user.id}' has Stripe ID '#{current_user.stripe_customer_id}' but completed checkout had '#{customer_id}' (session '#{session.id}')"
    end

    subscription_id = session.subscription

    raise "Stripe session '#{session.id}' has no subscription ID" if subscription_id.nil?

    create_and_refresh_subscription(subscription_id)

    redirect_to @tile.present? ? tile_path(@tile) : project_path(@project),
                flash: { success: 'Your subscription has been successfully set up!' }
  end

  private

  def derive_success_url(tile)
    project = tile&.plot&.project || Project.first

    # Workaround to build URL because encoding '{' and '}' breaks Stripe's template variable substitution
    "#{checkout_success_url(project: project.hashid, tile: tile&.hashid)}&session_id={CHECKOUT_SESSION_ID}"
  end

  def stripe_checkout_payload(promo_code, tile)
    x = {
      # Stripe will create new customer if not supplied
      customer: current_user.stripe_customer_id,
      line_items: [{
        price: @price.stripe_id,
        quantity: 1
      }],
      metadata: {
        tile: tile&.hashid
      },
      mode: 'subscription',
      ui_mode: 'embedded',
      return_url: derive_success_url(tile)
    }
    if promo_code.nil?
      x[:allow_promotion_codes] = true
    else
      x[:discounts] = [{ promotion_code: promo_code&.stripe_id }]
    end
    x
  end

  def create_stripe_checkout(promo_code: nil, tile: nil)
    @stripe_checkout = Stripe::Checkout::Session.create(stripe_checkout_payload(promo_code, tile))
    nil # return no error
  rescue Stripe::InvalidRequestError => e
    raise e unless e.message == 'This promotion code cannot be redeemed because the associated customer has prior transactions.'

    # TODO: Handle when e.message.start_with?('Coupon expired')
    "You've already used this promo code so can't subscribe with this again"
  end

  def set_price
    @price = Price.find_by_hashid!(params[:price])
  end

  def set_tile
    @tile = Tile.find_by_hashid(params[:tile]&.upcase)
  end

  def set_project
    @project = Project.find_by_hashid!(params[:project]&.upcase)
  end

  def create_and_refresh_subscription(subscription_id)
    subscription = current_user.subscriptions_subscribed.create_with(
      stripe_status: :active, # reasonably assumed
      tile: @tile
    ).find_or_create_by!(
      stripe_id: subscription_id
    )

    StripeSubscriptionRefreshJob.perform_later(subscription)
  end
end
