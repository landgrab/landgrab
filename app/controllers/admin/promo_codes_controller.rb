# frozen_string_literal: true

module Admin
  class PromoCodesController < ApplicationController
    before_action :check_admin
    before_action :set_promo_code, only: %i[show edit update]

    def index
      @promo_codes = PromoCode.order(id: :desc).page(params[:page])
    end

    def show; end

    def new
      @promo_code = PromoCode.new
    end

    def edit; end

    def create
      @promo_code = PromoCode.new(promo_code_params)

      if @promo_code.save
        redirect_to admin_promo_code_path(@promo_code), notice: 'Promo code was successfully created.'
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @promo_code.update(promo_code_params)
        redirect_to admin_promo_code_path(@promo_code), notice: 'Promo code was successfully updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_promo_code
      @promo_code = PromoCode.find_by_hashid!(params[:id])
    end

    def promo_code_params
      params.expect(promo_code: %i[code stripe_id free_trial_days])
    end
  end
end
