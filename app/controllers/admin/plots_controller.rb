# frozen_string_literal: true

module Admin
  class PlotsController < ApplicationController
    before_action :check_admin
    before_action :set_plot, only: %i[show edit update]

    def index
      @project = Project.find_by_hashid!(params[:project]) if params[:project].present?
      @plots = @project.present? ? @project.plots : Plot.includes(:project)
      @plots = @plots.order(id: :desc).page(params[:page])
    end

    def show; end

    def new
      project = Project.find_by_hashid(params[:project_id]) if params[:project_id].present?
      @plot = Plot.new(project:)
    end

    def edit; end

    def create
      @plot = Plot.new(plot_params)
      if @plot.save
        PlotTilesPopulateJob.perform_later(@plot.id)

        redirect_to admin_plot_path(@plot), notice: 'Plot was successfully created.'
      else
        render :new
      end
    end

    def update
      if @plot.update(plot_params)
        if @plot.previous_changes.key?('polygon')
          @plot.update!(tile_population_status: :pending)
          PlotTilesPopulateJob.perform_later(@plot.id)
        end

        redirect_to admin_plot_path(@plot), notice: 'Plot was successfully updated.'
      else
        render :edit
      end
    end

    private

    def set_plot
      @plot = Plot.find_by_hashid!(params[:id])
    end

    def plot_params
      params.expect(plot: [:title, :description, :polygon, :project_id, :hero_image_url])
    end
  end
end
