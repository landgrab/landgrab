# frozen_string_literal: true

# Decides how each tile on a map is drawn: a fill colour for whose tile it is
# (or whether it is available) and a border for what it means to the viewer or
# the page. Also builds the matching legend.
class TileMap
  ORANGE = '#dc6c2a'
  LIME = '#b7de33'
  BLUE = '#1d49a7'
  RED = '#a32720'
  GREEN = '#518c3c'
  EMERALD = '#00322f'
  WHITE = '#ffffff'

  FILLS = { mine: ORANGE, redeemed: ORANGE, team: ORANGE, gifted: LIME, referred: BLUE, available: GREEN, unavailable: RED }.freeze
  LEGEND_ORDER = %i[mine redeemed team gifted referred focus available unavailable].freeze

  attr_reader :highlighter, :focus_title

  # tiles:       the tiles the page wants shown
  # plot:        when given, the viewer's and subject's highlighted tiles in it are always shown
  # focus_tiles: the tiles the page is about (e.g. "This tile"), drawn with a white border
  # highlighter: a TileHighlightService or TeamTileHighlightService, which classifies
  #              highlighted tiles and names them in the legend
  def initialize(tiles:, highlighter:, plot: nil, focus_tiles: [], focus_title: 'This tile')
    @highlighter = highlighter
    @plot = plot
    @requested_tiles = tiles.to_a
    @focus_tiles = focus_tiles.to_a.compact
    @focus_title = focus_title
  end

  # Tiles with their map colour and border set, bordered tiles last so
  # neighbouring tiles don't draw over their borders.
  def tiles
    @tiles ||= all_tiles.each { |tile| style(tile) }.sort_by { |tile| tile.map_border.present? ? 1 : 0 }
  end

  def legend
    counts = tiles.map { |tile| category(tile) }.tally
    counts[:focus] = tiles.count { |tile| focus?(tile) }

    LEGEND_ORDER.filter_map do |key|
      count = counts.fetch(key, 0)
      next unless count.positive?

      { key:, title: label(key, count), fill: legend_fill(key), border: legend_border(key) }
    end
  end

  private

  def all_tiles
    extra = @plot.present? ? highlighter.highlighted_tiles(plot: @plot).to_a : []
    tiles = (@focus_tiles + extra + @requested_tiles).uniq
    ActiveRecord::Associations::Preloader.new(records: tiles.select(&:persisted?), associations: :latest_subscription).call
    tiles
  end

  def style(tile)
    tile.map_colour = FILLS.fetch(category(tile))
    tile.map_border = border(tile)
  end

  def category(tile)
    highlighter.category_for(tile) || (tile.available? ? :available : :unavailable)
  end

  def focus?(tile)
    @focus_tiles.include?(tile)
  end

  def border(tile)
    return WHITE if focus?(tile)

    EMERALD if category(tile) == :mine
  end

  def legend_fill(key)
    FILLS[key] # nil for focus: it's an outline on whatever fill the tile has
  end

  def legend_border(key)
    { mine: EMERALD, focus: WHITE }[key]
  end

  def label(key, count)
    case key
    when :focus then focus_title
    when :available, :unavailable then key.to_s.humanize
    else highlighter.label(key, count)
    end
  end
end
