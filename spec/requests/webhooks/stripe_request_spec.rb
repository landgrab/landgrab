# frozen_string_literal: true

require 'support/stripe_test_helper'

RSpec.describe 'StripeWebhook' do
  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('STRIPE_WEBHOOK_SIGNING_SECRET').and_return('whsec_abc123')
  end

  describe 'GET #webhook' do
    subject(:run_hook) { post '/webhook/stripe', params: webhook_params.to_json, headers: }

    let(:headers) { { 'stripe-signature' => stripe_generate_header(payload: webhook_params.to_json) } }

    let(:webhook_params) { json_fixture('stripe/webhooks/checkout_session_completed') }

    it 'returns a 200 status code with json content type' do
      run_hook

      expect(response).to have_http_status(:ok)
    end

    it 'refreshes the stripe subscription' do
      expect { run_hook }.to enqueue_job(StripeSubscriptionCreateOrRefreshJob)
    end
  end
end
