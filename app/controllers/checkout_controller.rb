# frozen_string_literal: true

class CheckoutController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[checkout generate]

  before_action :ensure_stripe_enrollment, only: %i[checkout]

  before_action :set_project, only: %i[checkout]
  before_action :set_tile, only: %i[checkout]
  before_action :set_price, only: %i[checkout]
  before_action :set_redemption_mode, only: %i[checkout]
  before_action :set_promo_code, only: %i[checkout]

  # See docs/CHECKOUT.md
  def checkout
    unless user_signed_in?
      redirect_to new_user_registration_path,
                  flash: { notice: 'Please register so we can link the subscription to an account' }
      return
    end

    @stripe_err = 'You did not select a price' if @price.nil?
    @stripe_err ||= create_stripe_checkout

    log_error("Checkout error: #{@stripe_err}") if @stripe_err.present?
    log_event_mixpanel('Checkout: Checkout', { authed: user_signed_in? })
  end

  def generate
    log_event_mixpanel('Checkout: Generate', { authed: user_signed_in? })

    # Redirect to support legacy links; 'generate' is no longer supported
    redirect_to checkout_checkout_path(code: params[:code], price: params[:price], tile: params[:tile])
  end

  def success
    log_event_mixpanel('Checkout: Success')

    subscription_id = nil
    5.times do # allow for delay in the subscription being linked to session
      session = retrieve_authorised_checkout_session

      return redirect_to checkout_checkout_path, flash: { danger: 'Subscription not completed.' } unless session.status == 'complete'

      subscription_id = session.subscription
      break if subscription_id.present?

      sleep 1
    end

    raise "Stripe session '#{session.id}' has no sub ID (after 5 attempts)" if subscription_id.nil?

    @subscription = StripeSubscriptionCreateOrRefreshJob.perform_now(subscription_id)

    redirect_to after_subscription_success_location, flash: { success: 'Subscription created successfully!' }
  end

  private

  def build_success_url
    # Manually build URL because encoding '{' and '}' breaks Stripe's template variable substitution
    "#{checkout_success_url}?session_id={CHECKOUT_SESSION_ID}"
  end

  def stripe_checkout_payload
    x = {
      customer: current_user.stripe_customer_id,
      line_items: [{
        price: @price.stripe_id,
        quantity: 1
      }],
      subscription_data: { metadata: stripe_checkout_payload_subscription_metadata },
      mode: 'subscription',
      ui_mode: 'embedded',
      return_url: build_success_url
    }
    if @promo_code.nil?
      x[:allow_promotion_codes] = true
    else
      x[:discounts] = [{ promotion_code: @promo_code&.stripe_id }]
    end
    x
  end

  def stripe_checkout_payload_subscription_metadata
    # Data to be stored with the subscription: https://docs.stripe.com/api/checkout/sessions/create#create_checkout_session-subscription_data-metadata
    {
      project: @project.hashid,
      tile: @tile&.hashid,
      CheckoutService::REDEMPTION_MODE_KEY => @redemption_mode
    }
  end

  def create_stripe_checkout
    @stripe_checkout = Stripe::Checkout::Session.create(stripe_checkout_payload)
    nil # return no error
  rescue Stripe::InvalidRequestError => e
    raise e unless e.message == 'This promotion code cannot be redeemed because the associated customer has prior transactions.'

    # TODO: Handle when e.message.start_with?('Coupon expired')
    "You've already used this promo code so can't subscribe with this again"
  end

  def set_project
    # TODO: Stop relying on `Project.first` fallback
    @project = params[:project].present? ? Project.find_by_hashid!(params[:project]&.upcase) : Project.first
  end

  def set_tile
    # TODO: Look only in the project's tiles (to prevent mismatched tile<>project)
    @tile = Tile.find_by_hashid!(params[:tile].upcase) if params[:tile].present?
  end

  def set_price
    @price = Price.find_by_hashid!(params[:price].upcase) if params[:price].present?
  end

  def set_redemption_mode
    @redemption_mode = params[:redemption_mode] if params[:redemption_mode].present?

    raise "Invalid redemption mode: #{@redemption_mode}" unless [nil, CheckoutService::REDEMPTION_MODE_SELF, CheckoutService::REDEMPTION_MODE_GIFT].include?(@redemption_mode)
  end

  def set_promo_code
    @promo_code = PromoCode.find_by!(code: params[:code]) if params[:code].present?
  end

  def retrieve_authorised_checkout_session
    Stripe::Checkout::Session.retrieve(params[:session_id]).tap do |session|
      unless current_user.stripe_customer_id == session.customer
        raise "Customer mismatch for User##{current_user.hashid}; user_cust=#{current_user.stripe_customer_id}; session_cust=#{session.customer} (session_id=#{session.id})"
      end
    end
  end

  def after_subscription_success_location
    # If already (immediately) redeemed, redirect to tile (or project)
    return (@subscription.tile.present? ? tile_path(@subscription.tile) : project_path(@subscription.project)) if @subscription.redeemed?

    # ... otherwise show the subscription, where user can choose what to do next (i.e. redeem or gift)
    subscription_path(@subscription)
  end
end
