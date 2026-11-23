# frozen_string_literal: true

# What a project page's map shows: an overview of the project's plot outlines,
# coloured and labelled by how many available tiles each has, drilling into a
# sample of each plot's tiles. Also totals the project's tiles.
class ProjectMap
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
      count_limit: exact_available_tile_count_limit,
      colour: ->(count) { count.positive? ? TileMap::GREEN : TileMap::RED }
    )
  end

  def tile_count
    @tile_count ||= Tile.where(plot: plots).count
  end

  private

  # A plot's map sample holds at least MAP_TILE_LIMIT - MAP_UNAVAILABLE_TILE_LIMIT of its
  # available tiles (or all of them, if it has fewer). A sample holding exactly that many
  # can't tell "that many" from "more", so counts are only exact up to one below it, and a
  # count above that means there are more.
  def exact_available_tile_count_limit
    Plot::MAP_TILE_LIMIT - Plot::MAP_UNAVAILABLE_TILE_LIMIT - 1
  end
end
