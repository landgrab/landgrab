# frozen_string_literal: true

# How many tiles, and how many available tiles, each of some plots has,
# counted for all the plots at once rather than one plot at a time.
class PlotTileCounts
  def initialize(plots)
    tiles = Tile.where(plot: plots)
    @totals = count_by_plot(tiles)
    @available = count_by_plot(tiles.available)
  end

  def total(plot)
    @totals.fetch(plot.id, 0)
  end

  def available(plot)
    @available.fetch(plot.id, 0)
  end

  private

  def count_by_plot(tiles)
    tiles.unscope(:order).group(:plot_id).count
  end
end
