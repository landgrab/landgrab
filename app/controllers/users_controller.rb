# frozen_string_literal: true

class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: :profile

  def me
    return redirect_to user_profile_path(current_user.username) if current_user.username.present?

    @profile_user = current_user
    @tiles_by_plot = active_redeemed_tiles_by_plot(@profile_user)
  end

  def profile
    @profile_user = User.find_by!(username: params.expect(:username))
    @tiles_by_plot = active_redeemed_tiles_by_plot(@profile_user)
  end

  private

  def active_redeemed_tiles_by_plot(user)
    Tile
      .joins(:subscriptions)
      .where(subscriptions: { redeemer_id: user.id, stripe_status: :active })
      .distinct
      .includes(:plot, :latest_subscription)
      .group_by(&:plot)
      .reject { |plot, _| plot.nil? }
  end
end
