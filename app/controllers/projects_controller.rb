# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show welcome find_tile posts]
  skip_before_action :authenticate_user!, only: %i[index show find_tile]

  def index
    log_event_mixpanel('Projects: Index', { authed: user_signed_in? })
    @projects = Project.where(public: true).order(id: :desc).page(params[:page])
  end

  def show
    log_event_mixpanel('Projects: Show', { authed: user_signed_in?, project: @project.hashid })
  end

  def posts; end

  def welcome
    log_event_mixpanel('Projects: Welcome', { authed: user_signed_in?, project: @project.hashid })
  end

  def find_tile
    @tiles = Tile.where(plot: @project.plots).includes(:latest_subscription)
    log_event_mixpanel('Projects: Find Tile', { authed: user_signed_in?, project: @project.hashid })
  end

  private

  def set_project
    @project = Project.find_by_hashid!(params[:id])
  end
end
