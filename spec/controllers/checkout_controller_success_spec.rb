# frozen_string_literal: true

RSpec.describe CheckoutController do
  render_views

  let(:user) { create(:user, stripe_customer_id: "cus_#{rand(999_999)}") }
  let(:project) { create(:project) }
  let(:tile) { create(:tile) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('STRIPE_PUBLISHABLE_KEY').and_return('pk_test_123456')
  end

  describe 'GET checkout#success' do
    subject(:do_get) { get :success, params: { session_id: 'cs_test_abc123' } }

    let(:subscription_stripe_id) { 'sub_9988776655' }

    let(:cs_body) do
      stripe_fixture('checkout_sessions/complete').tap do |x|
        x[:customer] = user.stripe_customer_id
        x[:subscription] = subscription_stripe_id
      end
    end

    let(:subscription) { create(:subscription, stripe_id: subscription_stripe_id, project:, subscriber: user) }

    before do
      sign_in(user)

      stub_stripe_api(:get, 200, 'checkout/sessions/cs_test_abc123', cs_body)

      allow(Stripe::Checkout::Session).to receive(:retrieve).and_call_original
      allow(StripeSubscriptionCreateOrRefreshJob).to receive(:perform_now).and_return(subscription)
    end

    it 'retrieves the checkout session data' do
      do_get

      expect(Stripe::Checkout::Session).to have_received(:retrieve).with('cs_test_abc123')
    end

    it 'triggers a subscription creation job' do
      do_get

      expect(StripeSubscriptionCreateOrRefreshJob).to have_received(:perform_now).with(subscription_stripe_id)
    end

    context 'when user is logged out' do
      before do
        sign_out(user)
      end

      it 'redirects to the login page' do
        get :success

        expect(response).to redirect_to(new_user_session_url)
      end
    end

    context 'when subscription is not complete' do
      before do
        stub_stripe_api(:get, 200, 'checkout/sessions/cs_test_abc123', cs_body.tap { |x| x[:status] = 'open' })
      end

      it 'redirects back to checkout with error' do
        do_get

        expect(response).to redirect_to(checkout_checkout_url)
        expect(flash[:danger]).to include('not completed')
      end
    end

    context 'when subscription is redeemed by current user' do
      before do
        subscription.update!(redeemer: user)
      end

      it 'redirects to project if tile not set' do
        do_get

        expect(response).to redirect_to(project_path(project))
        expect(flash[:success]).to include('Subscription created successfully!')
      end

      it 'redirects to tile if set' do
        subscription.update!(tile:)

        do_get

        expect(response).to redirect_to(tile_path(tile))
        expect(flash[:success]).to include('Subscription created successfully!')
      end
    end
  end
end
