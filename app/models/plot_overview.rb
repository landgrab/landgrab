# frozen_string_literal: true

# The plot outlines a map opens on before drilling into tiles, each labelled
# with how many of the given tiles it contains.
class PlotOverview
  attr_reader :plots

  # plots:       the plots to outline
  # tiles:       the tiles to count in each plot (e.g. a team's team tiles)
  # tile_name:   what to call those tiles in each plot's label
  # count_limit: when given, a plot with more tiles than this is labelled "over <limit>",
  #              for when the tiles are a sample that is only complete up to it
  # colour:      outline colour for a plot, given its tile count
  def initialize(plots:, tiles:, tile_name: 'tile', count_limit: nil, colour: ->(_count) { TileMap::ORANGE })
    @plots = plots.to_a.sort_by(&:title)
    @tile_counts = tiles.to_a.map(&:plot_id).tally
    @tile_name = tile_name
    @count_limit = count_limit
    @colour = colour
  end

  def tile_count(plot)
    @tile_counts.fetch(plot.id, 0)
  end

  def label(plot)
    "#{plot.title}: #{count_text(capped_count(plot), over_limit: over_limit?(plot))} #{@tile_name.pluralize(tile_count(plot))}"
  end

  # The tiles across every plot, e.g. "1,234" or, when any plot is over the
  # count limit, "over 1,234" (counting each such plot at the limit).
  def total_text
    count_text(plots.sum { |plot| capped_count(plot) }, over_limit: plots.any? { |plot| over_limit?(plot) })
  end

  def to_geojson
    plots.map { |plot| feature(plot) }.to_json
  end

  private

  def over_limit?(plot)
    @count_limit.present? && tile_count(plot) > @count_limit
  end

  def capped_count(plot)
    over_limit?(plot) ? @count_limit : tile_count(plot)
  end

  def count_text(count, over_limit:)
    delimited = ActiveSupport::NumberHelper.number_to_delimited(count)
    over_limit ? "over #{delimited}" : delimited
  end

  def feature(plot)
    {
      type: 'Feature',
      geometry: RGeo::GeoJSON.encode(plot.polygon),
      properties: { id: plot.id, title: plot.title, label: label(plot), tile_count: tile_count(plot), colour: @colour.call(tile_count(plot)) }
    }
  end
end
