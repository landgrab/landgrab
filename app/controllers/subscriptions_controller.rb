# frozen_string_literal: true

# rubocop:disable Metrics/PerceivedComplexity
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
    if user_signed_in?
      @subscription = Subscription.find_by_hashid(params[:id])
      # TODO: Set 'project' on a subscription and redirect to that!
      if @subscription.nil?
        redirect_to support_path, flash: { danger: 'We could not find a subscription; please contact us.' }
      elsif params[:hash].blank?
        redirect_to support_path, flash: { danger: 'That link is missing something; please contact us.' }
      elsif !ActiveSupport::SecurityUtils.secure_compare(@subscription.claim_hash, params[:hash])
        redirect_to support_path, flash: { danger: "That link doesn't look quite right; please contact us." }
      elsif @subscription.subscriber.present?
        if @subscription.subscriber == current_user
          redirect_to welcome_project_path(@subscription.project_fallback), flash: { notice: 'This subscription is already linked to your account' }
        else
          redirect_to support_path, flash: { danger: 'Oh! This subscription is already connected to a different account. Have you got two accounts? Please reach out to us and we can help.' }
        end
      else
        @subscription.update!(subscriber: current_user)
        redirect_to welcome_project_path(@subscription.project_fallback), flash: { notice: "Great; you've subscribed! Next step is to pick a tile!" }
      end
    else
      redirect_to new_registration_path(:user, email: params[:email]), flash: { notice: 'Please register an account (or login) to claim your tile' }
    end
  end

  # User linking their (existing, unredeemed) subscription to a tile
  def redeem
    log_event_mixpanel('Subscriptions: Redeem')
    @tile = Tile.find_by_hashid!(params[:tile])

    return redirect_to support_path, flash: { danger: 'Sorry; this tile is not available! Please pick another.' } if @tile.unavailable?

    if @subscription.tile.present?
      flash = if @subscription.tile == @tile
                { notice: 'All good; the subscription was already redeemed against this tile!' }
              else
                { danger: "Sorry; this subscription has already been associated to tile ///#{@subscription.tile.w3w}" }
              end
    else
      @subscription.update!(tile: @tile)
      flash = { notice: "Congratulations! You're now subscribed to this tile!" }
    end

    redirect_to tile_path(@subscription.tile), flash:
  end

  private

  def set_subscription
    @subscription = current_user.subscriptions.find_by_hashid!(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(:tile_id)
  end
end
# rubocop:enable Metrics/PerceivedComplexity
