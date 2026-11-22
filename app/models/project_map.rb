# frozen_string_literal: true

# What a project page's map shows: an overview of the project's plot outlines,
# coloured and labelled by how many available tiles each has, drilling into a
# sample of each plot's tiles. Also totals the project's tiles.
class ProjectMap
  # A plot's map sample includes every one of its available tiles up to this many,
  # so counting the sample is exact up to here and a lower bound beyond it.
  EXACT_AVAILABLE_TILE_COUNT_LIMIT = Plot::MAP_TILE_LIMIT - Plot::MAP_UNAVAILABLE_TILE_LIMIT

  attr_reader :project, :plots

  def initialize(project)
    @project = project
    @plots = project.plots.where(id: Tile.select(:plot_id)).to_a
  end

  delegate :empty?, to: :plots

  def tiles
    @tiles ||= plots.flat_map(&:tiles_for_map)
  end

  def plot_overview
    @plot_overview ||= PlotOverview.new(
      plots:,
      tiles: tiles.select(&:available?),
      tile_name: 'available tile',
      count_limit: EXACT_AVAILABLE_TILE_COUNT_LIMIT,
      colour: ->(count) { count.positive? ? TileMap::GREEN : TileMap::RED }
    )
  end

  def tile_count
    @tile_count ||= Tile.where(plot: plots).count
  end
end
