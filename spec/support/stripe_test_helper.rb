# frozen_string_literal: true

# Based on the Stripe Ruby SDK's own tests;
# https://github.com/stripe/stripe-ruby/blob/master/test/stripe/webhook_test.rb
module StripeTestHelper
  def stripe_generate_header(payload:)
    time = Time.zone.now
    secret = ENV.fetch('STRIPE_WEBHOOK_SIGNING_SECRET')
    signature = Stripe::Webhook::Signature.compute_signature(time, payload, secret)
    Stripe::Webhook::Signature.generate_header(time, signature)
  end

  def stripe_fixture(filename)
    # We should use `.to_hash` on Stripe responses to avoid unhelpful nested `StripeObject`s.
    # In our specs (here), we load json and force symbol keys for compatibility
    filename = "stripe/#{filename}" unless filename.start_with?('stripe/')
    json_fixture(filename).deep_symbolize_keys
  end

  # Stub the low-level Stripe API request
  # method => HTTP verb (as symbol) to expect for the request (eg. :post)
  # status => response code (200 or 4XX) - see https://stripe.com/docs/api/errors
  # path => Stripe API path AND local fixtures directory (eg. 'payment_intents')
  # filename => JSON fixture (relative to 'path' folder)
  def stub_stripe_api(method, status, path, resp_or_fixture_name, query_params = nil)
    resp = resp_or_fixture_name.is_a?(String) ? stripe_fixture(resp_or_fixture_name) : resp_or_fixture_name

    urlpath = query_params.nil? ? path : "#{path}?#{query_params}"
    stub_request(method, stripe_api_url(urlpath))
      .to_return(status:, body: resp.to_json)
  end

  private

  def stripe_api_url(path)
    "https://api.stripe.com/v1/#{path}"
  end
end
