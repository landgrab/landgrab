# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  def index
    log_event_mixpanel('Subscriptions: Index')
    @subscriptions = current_user.associated_subscriptions.includes(:redeemer, tile: { plot: :project })
  end

  def show
    @subscription = current_user.associated_subscriptions.find_by_hashid!(params[:id])
    log_event_mixpanel('Subscriptions: Show')
  end

  def link_tile
    @subscription = Subscription.find_by_hashid!(params[:id])

    # if @subscription.subscribed_by?(current_user)

    if @subscription.redeemed?
      if @subscription.redeemed_by?(current_user)
        redirect_to @subscription, flash: { notice: 'This subscription is already linked to your account' }
      else
        redirect_to support_path, flash: { danger: 'Oh! This subscription is already connected to a different account. Have you got two accounts? Please reach out to us and we can help.' }
      end
    end

    log_event_mixpanel('Subscriptions: Redeem')
    @tile = Tile.find_by_hashid!(params[:tile_hashid])

    flash = redeem_tile
    redirect_to tile_path(@tile), flash:
  end

  private

  def subscription_params
    params.require(:subscription).permit(:tile_id)
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
