# frozen_string_literal: true

class TeamsController < ApplicationController
  before_action :set_team, only: %i[show embed posts]

  skip_before_action :authenticate_user!, only: %i[show embed]
  skip_before_action :store_location, only: %i[embed]

  def show
    log_event_mixpanel('Teams: Show', { authed: user_signed_in?, team: @team.slug })
  end

  def embed
    @tiles = @team.subscribed_tiles

    render_embed
  end

  def posts; end

  private

  def set_team
    @team = Team.find_by!(slug: params[:id]&.downcase)
  end
end
