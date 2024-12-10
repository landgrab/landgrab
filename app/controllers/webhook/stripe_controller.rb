# frozen_string_literal: true

module Webhook
  class StripeController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    def webhook
      @event = parse_event

      # See https://stripe.com/docs/api/events/types
      case @event.type
      when 'checkout.session.completed'
        checkout_session_completed
      when /customer\.subscription\.*/
        refresh_subscription
      when 'invoice.paid'
        # TODO: invoice_paid
      when 'invoice.payment_failed'
        # TODO: invoice_payment_failed
      else
        raise "Unhandled event type: #{@event.type}"
      end

      head :ok
    end

    private

    def checkout_session_completed
      @checkout_session = @event.data.object

      # TODO: Check that current_user matches subscription user?
      user = extract_user
      tile = Tile.find_by_hashid(@checkout_session.metadata.tile) if @checkout_session.metadata.respond_to?(:tile)

      sub_id = @checkout_session.subscription

      # TODO: Check tile still available?

      subscr = Subscription.create!(subscriber: user, tile:, stripe_id: sub_id, stripe_status: :incomplete)

      StripeSubscriptionRefreshJob.perform_later(subscr)
    end

    def refresh_subscription
      sub_id = @event.data.object.id

      subscr = Subscription.find_by!(stripe_id: sub_id)

      StripeSubscriptionRefreshJob.perform_later(subscr)
    end

    def extract_user
      cus_id = @checkout_session.customer
      raise 'Missing customer ID from webhook body' if cus_id.blank?

      User.find_by(stripe_customer_id: cus_id)
    end

    def parse_event
      Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError
      raise 'Invalid JSON'
    rescue Stripe::SignatureVerificationError
      raise 'Invalid signature'
    end

    def payload
      request.body.read
    end

    def sig_header
      request.headers['HTTP_STRIPE_SIGNATURE']
    end

    def endpoint_secret
      ENV.fetch('STRIPE_WEBHOOK_SIGNING_SECRET')
    end
  end
end
