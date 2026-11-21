# frozen_string_literal: true

class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: :profile

  def me
    return redirect_to user_profile_path(current_user.username) if current_user.username.present?

    @profile_user = current_user
    load_impact
  end

  def profile
    @profile_user = User.find_by!(username: params.expect(:username))
    load_impact
  end

  private

  # The profile user's own, gifted and referred tiles, grouped by plot (most first)
  def load_impact
    highlighter = TileHighlightService.new(viewer: @profile_user)
    tiles = highlighter.highlighted_tiles.includes(:plot, :latest_subscription).select(&:plot)

    @impact_counts = tiles.map { |tile| highlighter.category_for(tile) }.tally
    @impact_plots = tiles.group_by(&:plot).sort_by { |_plot, plot_tiles| -plot_tiles.size }.map(&:first)
  end
end
