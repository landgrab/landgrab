# frozen_string_literal: true

module Admin
  class ProjectsController < ApplicationController
    before_action :check_admin
    before_action :set_project, only: %i[show edit update]

    def index
      @projects = Project.order(id: :desc).page(params[:page])
    end

    def show; end

    def new
      @project = Project.new
    end

    def edit; end

    def create
      @project = Project.new(project_params)

      if @project.save
        redirect_to admin_project_path(@project), notice: 'Project was successfully created.'
      else
        render :new
      end
    end

    def update
      if @project.update(project_params)
        redirect_to admin_project_path(@project), notice: 'Project was successfully updated.'
      else
        render :edit
      end
    end

    private

    def set_project
      @project = Project.find_by_hashid!(params[:id])
    end

    def project_params
      params
            .expect(
              project: [:title,
              :description,
              :website,
              :hero_image_url,
              :logo_url,
              :welcome_text,
              :subscriber_benefits,
              :public]
            )
    end
  end
end
