# frozen_string_literal: true

class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[about debug support homepage explore]

  def about
    log_event_mixpanel('About Page', { authed: user_signed_in? })
  end

  def support
    log_event_mixpanel('Support Page', { authed: user_signed_in? })
  end

  def homepage
    log_event_mixpanel('Home Page', { authed: user_signed_in? })
    if params[:center].present?
      tile = Tile.find_by(w3w: params[:center])
      @center = [tile.midpoint.y, tile.midpoint.x] if tile
    else
      @center = Plot::DEFAULT_COORDS
    end
  end

  def my_tile
    log_event_mixpanel('My Tile Shortcut', { authed: true })

    subs = current_user.subscriptions_subscribed
    if subs.none?
      redirect_to root_path,
                  alert: "You don't have a subscription yet"
    elsif subs.stripe_status_active.none?
      redirect_to subscriptions_path,
                  alert: 'Your subscription is not active'
    elsif subs.stripe_status_active.joins(:tile).none?
      redirect_to subscriptions_path,
                  alert: "You're subscribed, but haven't claimed a tile yet!"
    else
      claimed_subs = subs.stripe_status_active.joins(:tile)
      if claimed_subs.size > 1
        redirect_to subscriptions_path,
                    notice: "You've got multiple active tile subscriptions; choose one to view below."
      else
        redirect_to tile_path(claimed_subs.first.tile)
      end
    end
  end

  def explore
    log_event_mixpanel('Explore Page', { authed: user_signed_in? })
    @plot = Plot.select('plots.id, plots.title, COUNT(tiles)')
                .joins(:project)
                .where(projects: { public: true })
                .with_available_tiles
                .group('plots.id')
                .sample

    return redirect_to root_url, flash: { danger: 'No plots exist yet so nothing to explore!' } if @plot.nil?

    @available_limit = 200
    @available_tiles = @plot.tiles.available.includes(:latest_subscription).sample(@available_limit)
    @unavailable_tiles = @plot.tiles.unavailable.distinct.sample(250 - @available_tiles.size)
  end

  def debug; end
end
