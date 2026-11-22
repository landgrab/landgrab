# frozen_string_literal: true

# What a team's map shows: its team tiles plus a sample of each team plot's
# other tiles for context, opening on an overview of those plots' outlines.
class TeamMap
  attr_reader :team, :team_tiles, :team_plots

  def initialize(team)
    @team = team
    @team_tiles = team.team_tiles.to_a
    @team_plots = team.team_plots.to_a
  end

  delegate :empty?, to: :team_tiles

  def tiles
    @tiles ||= team_tiles + team_plots.flat_map(&:tiles_for_map)
  end

  def plot_overview
    @plot_overview ||= PlotOverview.new(plots: team_plots, tiles: team_tiles, tile_name: 'team tile')
  end
end
