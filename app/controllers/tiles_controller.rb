# frozen_string_literal: true

class TilesController < ApplicationController
  before_action :set_tile, only: %i[show embed posts]
  skip_before_action :authenticate_user!, only: %i[index embed show]
  skip_before_action :store_location, only: %i[embed]

  def embed
    render_embed
  end

  def index
    log_event_mixpanel('Tiles: Index', { authed: user_signed_in? })
    @plot = Plot.find_by_hashid!(params[:plot]) if params[:plot].present?
    if @plot.present?
      @tiles = @plot.tiles.order(id: :desc).includes(:latest_subscription).page(params[:page])
      @center = [@plot.centroid_coords.y, @plot.centroid_coords.x]
    else
      @tiles = Tile.order(id: :desc).includes(:plot, :latest_subscription).page(params[:page])
      @center = derive_tiles_center(@tiles)
    end
  end

  def show
    log_event_mixpanel('Tiles: Show', { authed: user_signed_in?, tile: @tile.hashid, plot: @tile.plot&.hashid, project: @tile.project&.hashid })
  end

  def posts; end

  private

  def set_tile
    @tile = Tile.find_by_hashid!(params[:id])
  end

  def derive_tiles_center(tiles)
    return Plot::DEFAULT_COORDS if tiles.none?

    mean_x = tiles.sum { |b| b.midpoint.x } / tiles.size
    mean_y = tiles.sum { |b| b.midpoint.y } / tiles.size

    [mean_y, mean_x]
  end
end
