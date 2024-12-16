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

      subscription_stripe_id = @checkout_session.subscription

      StripeSubscriptionCreateOrRefreshJob.perform_later(subscription_stripe_id)
    end

    def refresh_subscription
      subscription_stripe_id = @event.data.object.id

      StripeSubscriptionCreateOrRefreshJob.perform_later(subscription_stripe_id)
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
      request.headers['http_stripe_signature']
    end

    def endpoint_secret
      ENV.fetch('STRIPE_WEBHOOK_SIGNING_SECRET')
    end
  end
end
