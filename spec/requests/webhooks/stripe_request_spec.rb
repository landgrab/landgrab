# frozen_string_literal: true

require 'support/stripe_test_helper'

RSpec.describe 'StripeWebhook' do
  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('STRIPE_WEBHOOK_SIGNING_SECRET').and_return('whsec_abc123')
  end

  describe 'GET #webhook' do
    subject(:run_hook) { post '/webhook/stripe', params: webhook_params.to_json, headers: }

    let(:headers) do
      {
        'stripe-signature' => stripe_generate_header(payload: webhook_params.to_json),
        'CONTENT_TYPE' => 'application/json'
      }
    end

    let(:webhook_params) { json_fixture('stripe/webhooks/checkout_session_completed') }

    it 'returns a 200 status code with json content type' do
      run_hook

      expect(response).to have_http_status(:ok)
    end

    it 'refreshes the stripe subscription' do
      expect { run_hook }.to enqueue_job(StripeSubscriptionCreateOrRefreshJob)
    end

    context 'with a subscription deleted (cancelled) event' do
      let(:webhook_params) do
        { id: 'evt_cancel', object: 'event', type: 'customer.subscription.deleted',
          data: { object: { id: 'sub_abc123', object: 'subscription', status: 'canceled' } } }
      end

      it 'refreshes that stripe subscription' do
        expect { run_hook }.to have_enqueued_job(StripeSubscriptionCreateOrRefreshJob).with('sub_abc123')
      end
    end

    context 'with an event type we do not handle' do
      let(:webhook_params) do
        { id: 'evt_other', object: 'event', type: 'customer.updated',
          data: { object: { id: 'cus_abc123', object: 'customer' } } }
      end

      it 'acknowledges it with a 200 so Stripe does not retry or disable the endpoint' do
        run_hook

        expect(response).to have_http_status(:ok)
      end

      it 'does not enqueue a refresh' do
        expect { run_hook }.not_to enqueue_job(StripeSubscriptionCreateOrRefreshJob)
      end
    end
  end
end
