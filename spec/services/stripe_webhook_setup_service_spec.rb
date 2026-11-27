# frozen_string_literal: true

RSpec.describe StripeWebhookSetupService do
  subject(:service) { described_class.new('https://example.com/') }

  let(:url) { 'https://example.com/webhook/stripe' }
  let(:events) { described_class::ENABLED_EVENTS }

  def endpoint_json(overrides = {})
    { id: 'we_123', object: 'webhook_endpoint', url:, status: 'enabled', enabled_events: events }.merge(overrides)
  end

  def stub_list(data)
    stub_request(:get, %r{api.stripe.com/v1/webhook_endpoints})
      .to_return(status: 200, body: { object: 'list', data:, has_more: false, url: '/v1/webhook_endpoints' }.to_json)
  end

  it 'builds the endpoint url from the base url' do
    expect(service.url).to eq(url)
  end

  it 'includes the subscription cancellation event' do
    expect(events).to include('customer.subscription.deleted')
  end

  context 'when no endpoint exists for the url' do
    let!(:create_request) do
      stub_list([endpoint_json(url: 'https://other.example.com/webhook/stripe', id: 'we_other')])
      stub_request(:post, 'https://api.stripe.com/v1/webhook_endpoints')
        .to_return(status: 200, body: endpoint_json(secret: 'whsec_new').to_json)
    end

    it 'creates one and returns the signing secret' do
      result = service.call

      expect(result).to have_attributes(created: true, secret: 'whsec_new')
    end

    it 'subscribes it to the handled events' do
      service.call

      expect(create_request.with(body: /url=https%3A%2F%2Fexample.com%2Fwebhook%2Fstripe.*customer\.subscription\.deleted/)).to have_been_requested
    end
  end

  context 'when an endpoint already exists for the url' do
    before do
      stub_list([endpoint_json(status: 'disabled', enabled_events: ['customer.updated'])])
      stub_request(:post, 'https://api.stripe.com/v1/webhook_endpoints/we_123')
        .to_return(status: 200, body: endpoint_json.to_json)
    end

    it 'updates and re-enables it instead of creating a duplicate' do
      result = service.call

      expect(result).to have_attributes(created: false, secret: nil)
    end

    it 'resets the events and enables it' do
      service.call

      expect(WebMock).to have_requested(:post, 'https://api.stripe.com/v1/webhook_endpoints/we_123')
        .with(body: /customer\.subscription\.deleted.*disabled=false/)
    end
  end
end
