# frozen_string_literal: true

# Creates (or repairs) the Stripe webhook endpoint that feeds Webhook::StripeController.
# Idempotent: an existing endpoint for the same URL is updated and re-enabled rather than duplicated.
class StripeWebhookSetupService
  WEBHOOK_PATH = '/webhook/stripe'

  # Keep in sync with the events handled in Webhook::StripeController
  ENABLED_EVENTS = %w[
    checkout.session.completed
    customer.subscription.created
    customer.subscription.updated
    customer.subscription.deleted
    customer.subscription.paused
    customer.subscription.resumed
    customer.subscription.pending_update_applied
    customer.subscription.pending_update_expired
    customer.subscription.trial_will_end
  ].freeze

  # `secret` is only present when the endpoint was newly created (Stripe never returns it again)
  Result = Struct.new(:endpoint, :created, :secret, keyword_init: true)

  def initialize(base_url)
    @url = "#{base_url.to_s.chomp('/')}#{WEBHOOK_PATH}"
  end

  attr_reader :url

  def call
    existing = find_existing_endpoint

    if existing
      endpoint = Stripe::WebhookEndpoint.update(existing.id, enabled_events: ENABLED_EVENTS, disabled: false)
      Result.new(endpoint:, created: false)
    else
      endpoint = Stripe::WebhookEndpoint.create(url:, enabled_events: ENABLED_EVENTS)
      Result.new(endpoint:, created: true, secret: endpoint.secret)
    end
  end

  private

  def find_existing_endpoint
    Stripe::WebhookEndpoint.list(limit: 100).auto_paging_each.find { |endpoint| endpoint.url == url }
  end
end
