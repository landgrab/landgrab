# frozen_string_literal: true

module Admin
  class TeamsController < ApplicationController
    before_action :check_admin
    before_action :set_team, only: %i[show edit update]

    def index
      @teams = apply_scopes(Team).all

      respond_to do |format|
        format.html do
          @teams = @teams.order(id: :desc).page(params[:page])
          render :index
        end
        format.csv { render_csv('teams') }
      end
    end

    def show; end

    def new
      @team = Team.new
    end

    def edit; end

    def create
      @team = Team.new(team_params)

      if @team.save
        redirect_to admin_team_path(@team), notice: 'Team was successfully created.'
      else
        render :new
      end
    end

    def update
      if @team.update(team_params)
        redirect_to admin_team_path(@team), notice: 'Team was successfully updated.'
      else
        render :edit
      end
    end

    private

    def set_team
      @team = Team.find_by!(slug: params[:id])
    end

    def team_params
      params.expect(
        team: [:title,
        :slug,
        :logo_url,
        :website,
        :description]
      )
    end
  end
end
