# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: %i[redeem show]

  skip_before_action :authenticate_user!, only: %i[claim]

  def index
    log_event_mixpanel('Subscriptions: Index')
    @subscriptions = current_user.subscriptions_subscribed.includes(tile: { plot: :project })
  end

  def show
    log_event_mixpanel('Subscriptions: Show')
  end

  # User connecting to their subscription (after registration)
  def claim
    log_event_mixpanel('Subscriptions: Claim', { authed: user_signed_in? })

    unless user_signed_in?
      return redirect_to new_registration_path(:user, email: params[:email]),
                         flash: { notice: 'Please register an account (or login) to claim your tile' }
    end

    @subscription = Subscription.find_by_hashid!(params[:id])
    unless @subscription.verify_claims_hash(params[:hash])
      # TODO: Set 'project' on a subscription and redirect to that!
      return redirect_to support_path, flash: { danger: "That link doesn't look quite right; please contact us." }
    end

    if @subscription.subscriber.present?
      if @subscription.subscriber == current_user
        redirect_to welcome_project_path(@subscription.project_fallback), flash: { notice: 'This subscription is already linked to your account' }
      else
        redirect_to support_path, flash: { danger: 'Oh! This subscription is already connected to a different account. Have you got two accounts? Please reach out to us and we can help.' }
      end
    else
      @subscription.update!(subscriber: current_user)
      redirect_to welcome_project_path(@subscription.project_fallback), flash: { notice: "Great; you've subscribed! Next step is to pick a tile!" }
    end
  end

  # User linking their (existing, unredeemed) subscription to a tile
  def redeem
    log_event_mixpanel('Subscriptions: Redeem')
    @tile = Tile.find_by_hashid!(params[:tile])

    flash = redeem_tile
    redirect_to tile_path(@tile), flash:
  end

  private

  def set_subscription
    @subscription = current_user.subscriptions_subscribed.find_by_hashid!(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(:tile_id)
  end

  def redeem_tile
    if @tile.available?
      if @subscription.tile.nil?
        @subscription.update!(tile: @tile)
        { notice: "Congratulations! You're now subscribed to this tile!" }
      else
        { danger: "This subscription was already redeemed against another tile: ///#{@subscription.tile.w3w}" }
      end
    elsif @tile.subscribed_by?(current_user)
      { notice: "All good; you're already subscribed to this tile!" }
    else
      { danger: 'Sorry, this tile has already been claimed by someone else' }
    end
  end
end
