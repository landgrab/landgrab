# frozen_string_literal: true

module Admin
  class TilesController < ApplicationController
    before_action :check_admin
    before_action :set_tile, only: %i[show]

    def index
      @tiles = filtered_tiles

      respond_to do |format|
        format.html do
          @tiles = @tiles.order(id: :desc).includes(latest_subscription: :subscriber).page(params[:page])
          render :index
        end
        format.csv { render_csv('tiles') }
      end
    end

    def show; end

    def new
      @tile = Tile.new
    end

    def create
      @tile = Tile.new(tile_params)

      @tile.populate_coords if @tile.w3w.present?

      if @tile.save
        redirect_to admin_tile_path(@tile), notice: 'Tile was successfully created.'
      else
        render :new
      end
    end

    private

    def set_tile
      @tile = Tile.find_by_hashid!(params[:id])
    end

    def tile_params
      params.expect(tile: %i[southwest northeast w3w])
    end

    def filtered_tiles
      tiles = filter_by_plot
      tiles = filter_by_w3w(tiles) if params[:w3w]
      filter_by_subscription(tiles)
    end

    def filter_by_plot
      if params[:plot].present?
        if params[:plot] == 'BLANK'
          Tile.where(plot: nil)
        else
          @plot = Plot.find_by_hashid!(params[:plot])
          @plot.tiles
        end
      else
        Tile.includes(:plot)
      end
    end

    def filter_by_w3w(tiles)
      tiles.where('tiles.w3w LIKE ?', "%#{params[:w3w]}%")
    end

    def filter_by_subscription(tiles)
      case params[:subscribed]
      when 'true'
        tiles.joins(:latest_subscription)
      when 'false'
        tiles.where.missing(:latest_subscription)
      else
        tiles
      end
    end
  end
end
