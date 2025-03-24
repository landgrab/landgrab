# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    before_action :check_admin
    before_action :set_user, only: %i[show edit update]

    def index
      @users = filtered_users.includes(:team)
      if params[:redeemed_subscription_to_plot].present?
        plot_ids = params[:redeemed_subscription_to_plot].map { |x| Plot.decode_id(x) }
        @users = @users.joins(subscriptions_redeemed: { tile: :plot })
                       .where(subscriptions_redeemed: { stripe_status: %i[active trialing] })
                       .where(plots: { id: plot_ids })
                       .distinct
      end

      respond_to do |format|
        format.html do
          @users = @users.includes(:subscriptions_subscribed, :subscriptions_redeemed)
          @users = @users.order(id: :desc).page(params[:page])
          render :index
        end
        format.csv { render_csv('users') }
      end
    end

    def show; end

    def edit; end

    def update
      if @user.update(user_params_for_update)
        redirect_to admin_user_path(@user), notice: 'User was successfully updated.'
      else
        render :edit
      end
    end

    private

    def set_user
      @user = User.find_by_hashid!(params[:id])
    end

    def user_params_for_update
      params.expect(user: [:first_name, :last_name, :team_id])
    end

    # rubocop:disable Metrics/AbcSize
    def filtered_users
      users = User.all
      users = users.where('users.first_name ILIKE ?', "%#{params[:first_name]}%") if params[:first_name].present?
      users = users.where('users.last_name ILIKE ?', "%#{params[:last_name]}%") if params[:last_name].present?
      users = users.where('users.email ILIKE ?', "%#{params[:email]}%") if params[:email].present?
      users = users.where(users: { stripe_customer_id: params[:stripe_customer_id] }) if params[:stripe_customer_id].present?
      users = users.where(team_id: Team.find_by_hashid!(params[:team]).id) if params[:team].present?

      users
    end
    # rubocop:enable Metrics/AbcSize
  end
end
