# frozen_string_literal: true

module Admin
  class PricesController < ApplicationController
    before_action :check_admin
    before_action :set_price, only: %i[show edit update]

    def index
      @prices = Price.includes(:project).order(id: :desc).page(params[:page])
    end

    def show; end

    def new
      project = Project.find_by_hashid!(params[:project_id]) if params[:project_id].present?
      @price = Price.new(project:)
    end

    def edit; end

    def create
      @price = Price.new(price_params)

      if @price.save
        redirect_to admin_price_path(@price), notice: 'Price was successfully created.'
      else
        render :new
      end
    end

    def update
      if @price.update(price_params)
        redirect_to admin_price_path(@price), notice: 'Price was successfully updated.'
      else
        render :edit
      end
    end

    private

    def set_price
      @price = Price.find_by_hashid!(params[:id])
    end

    def price_params
      params.require(:price)
            .permit(
              :title,
              :amount_display,
              :project_id,
              :stripe_id
            )
    end
  end
end
