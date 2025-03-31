# frozen_string_literal: true

module Admin
  class SubscriptionsController < ApplicationController
    before_action :check_admin
    before_action :set_subscription, only: %i[show edit refresh update]

    def index
      @subscriptions = filtered_subscriptions

      respond_to do |format|
        format.html do
          @subscriptions = @subscriptions.includes(:subscriber, :redeemer, :tile).order(id: :desc).page(params[:page])
          render :index
        end
        format.csv { render_csv('subscriptions') }
      end
    end

    def show; end

    def edit; end

    def create
      @subscription = Subscription.new(subscription_params)
      if @subscription.save
        redirect_to admin_subscription_url(@subscription), notice: 'Subscription was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def refresh
      StripeSubscriptionCreateOrRefreshJob.perform_now(@subscription.stripe_id)

      redirect_to admin_subscription_url(@subscription), notice: 'Subscription status was refreshed from Stripe.'
    end

    def update
      @subscription.assign_attributes(subscription_params)

      if @subscription.tile&.unavailable?(allow_cancelled: true)
        @subscription.errors.add(:tile, 'is unavailable; unlink other subscriptions from it first')
      end

      # Do not use `valid?` as that would clear any error added above
      if @subscription.errors.none? && @subscription.save
        reset_previous_tile_latest_subscription

        redirect_to admin_subscription_path(@subscription), notice: 'Subscription was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_subscription
      @subscription = Subscription.find_by_hashid!(params[:id])
    end

    def subscription_params_parsed
      temp = params.dup
      { subscriber_id: User, redeemer_id: User, tile_id: Tile, project_id: Project }.each do |key, klass|
        temp[:subscription][key] = klass.decode_id(temp[:subscription][key]) if temp[:subscription][key].present?
      end
      temp
    end

    def subscription_params
      subscription_params_parsed.require(:subscription).permit(:subscriber_id, :redeemer_id, :tile_id, :project_id)
    end

    def reset_previous_tile_latest_subscription
      return unless @subscription.previous_changes.key?(:tile_id)

      old_tile_id = @subscription.previous_changes.dig(:tile_id, 0)
      return if old_tile_id.nil?

      Tile.find(old_tile_id).reset_latest_subscription!
    end

    # rubocop:disable Metrics/AbcSize
    def filtered_subscriptions
      subs = Subscription.all
      subs = subs.where(stripe_status: params[:stripe_status].compact_blank.map { |x| x == 'BLANK' ? nil : Subscription.stripe_statuses.fetch(x) }) if params[:stripe_status]
      subs = subs.where('stripe_id LIKE ?', "%#{params[:stripe_id]}%") if params[:stripe_id].present?
      subs = subs.joins(:subscriber).where(users: { id: User.decode_id(params[:subscriber_id]) }) if params[:subscriber_id].present?
      subs = subs.joins(:redeemer).where(users: { id: User.decode_id(params[:redeemer_id]) }) if params[:redeemer_id].present?
      subs
    end
    # rubocop:enable Metrics/AbcSize
  end
end
