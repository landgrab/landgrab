# frozen_string_literal: true

# The plot outlines a map opens on before drilling into tiles, each labelled
# with how many of the given tiles it contains.
class PlotOverview
  attr_reader :plots

  # plots:     the plots to outline
  # tiles:     the tiles to count in each plot (e.g. a team's team tiles)
  # tile_name: what to call those tiles in each plot's label
  def initialize(plots:, tiles:, tile_name: 'tile')
    @plots = plots.to_a.sort_by(&:title)
    @tile_counts = tiles.to_a.map(&:plot_id).tally
    @tile_name = tile_name
  end

  def tile_count(plot)
    @tile_counts.fetch(plot.id, 0)
  end

  def label(plot)
    "#{plot.title}: #{tile_count(plot)} #{@tile_name.pluralize(tile_count(plot))}"
  end

  def to_geojson
    plots.map { |plot| feature(plot) }.to_json
  end

  private

  def feature(plot)
    {
      type: 'Feature',
      geometry: RGeo::GeoJSON.encode(plot.polygon),
      properties: { title: plot.title, label: label(plot), tile_count: tile_count(plot), colour: TileMap::ORANGE }
    }
  end
end
