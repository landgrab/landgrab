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
      StripeSubscriptionRefreshJob.perform_now(@subscription)

      redirect_to admin_subscription_url(@subscription), notice: 'Subscription status was refreshed from Stripe.'
    end

    def update
      if @subscription.update(subscription_params)
        redirect_to admin_subscription_path(@subscription), notice: 'Subscription was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_subscription
      @subscription = Subscription.find_by_hashid!(params[:id])
    end

    def subscription_params
      temp = params.dup
      temp[:subscription][:subscriber_id] = User.decode_id(temp[:subscription][:subscriber_id]) if temp[:subscription][:subscriber_id].present?
      temp[:subscription][:redeemer_id] = User.decode_id(temp[:subscription][:redeemer_id]) if temp[:subscription][:redeemer_id].present?
      temp.require(:subscription).permit(:subscriber_id, :redeemer_id)
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
