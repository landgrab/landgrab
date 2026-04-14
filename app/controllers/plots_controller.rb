# frozen_string_literal: true

class PlotsController < ApplicationController
  before_action :set_plot, only: %i[show embed posts]
  skip_before_action :authenticate_user!, only: %i[show embed]

  def show
    log_event_mixpanel('Plots: Show', { authed: user_signed_in?, plot: @plot.hashid, project: @plot.project&.hashid })
  end

  def posts; end

  def embed
    render_embed
  end

  private

  def set_plot
    @plot = Plot.find_by_hashid!(params[:id])
  end
end
