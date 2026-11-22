# frozen_string_literal: true

class TeamsController < ApplicationController
  before_action :set_team, only: %i[show embed posts]
  before_action :set_map_tiles, only: %i[show embed]

  skip_before_action :authenticate_user!, only: %i[show embed]
  skip_before_action :store_location, only: %i[embed]

  def show
    log_event_mixpanel('Teams: Show', { authed: user_signed_in?, team: @team.slug })
  end

  def embed
    render_embed
  end

  def posts; end

  private

  def set_team
    @team = Team.find_by!(slug: params.expect(:id)&.downcase)
  end

  # The team's tiles, plus a sample of each of their plots' other tiles for context
  def set_map_tiles
    @team_tiles = @team.team_tiles.to_a
    @team_plots = @team.team_plots.to_a
    @tiles = @team_tiles + @team_plots.flat_map(&:tiles_for_map)
    @plot_overview = PlotOverview.new(plots: @team_plots, tiles: @team_tiles, tile_name: 'team tile')
  end
end
