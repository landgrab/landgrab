# frozen_string_literal: true

RSpec.describe CheckoutController do
  render_views

  let(:user) { create(:user, stripe_customer_id: "cus_#{rand(999_999)}") }
  let(:project) { create(:project) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('STRIPE_PUBLISHABLE_KEY').and_return('pk_test_123456')
  end

  describe 'GET checkout#success' do
    let(:subscription_stripe_id) { 'sub_9988776655' }

    let(:cs_body) do
      stripe_fixture('checkout_sessions/complete').tap do |x|
        x[:customer] = user.stripe_customer_id
        x[:subscription] = subscription_stripe_id
      end
    end

    let(:params) { { session_id: 'cs_test_abc123', project: project.hashid } }

    before do
      sign_in(user)

      stub_stripe_api(:get, 200, 'checkout/sessions/cs_test_abc123', cs_body)

      allow(Stripe::Checkout::Session).to receive(:retrieve).and_call_original
      allow(StripeSubscriptionCreateOrRefreshJob).to receive(:perform_now)
    end

    subject(:do_get) { get :success, params: }

    it 'retrieves the checkout session data' do
      do_get

      expect(Stripe::Checkout::Session).to have_received(:retrieve).with('cs_test_abc123')
    end

    it 'redirects to project page with flash message' do
      do_get

      expect(response).to redirect_to(project_path(project))
      expect(flash[:success]).to include('Your subscription has been successfully set up!')
    end

    it 'creates a subscription for the user' do
      expect { do_get }.to change(Subscription, :count).by(1)
    end

    it 'triggers a subscription refresh job' do
      do_get

      expect(StripeSubscriptionCreateOrRefreshJob).to have_received(:perform_now).with(subscription_stripe_id)
    end

    context 'with tile specified' do
      let(:tile) { create(:tile) }

      it 'redirects to tile page with flash message' do
        get :success, params: { session_id: 'cs_test_abc123', project: project.hashid, tile: tile.hashid }

        expect(response).to redirect_to(tile_path(tile))
        expect(flash[:success]).to include('Your subscription has been successfully set up!')
      end
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
        expect(flash[:danger]).to include('try again')
      end
    end

    context 'when subscription customer id mismatches current user' do
      before do
        user.update!(stripe_customer_id: 'cus_somethingelse')
      end

      it 'raises an error' do
        expect { do_get }.to raise_error(/Stripe Customer ID mismatch/)
      end
    end

    context 'when subscription already exists for this user' do
      before do
        create(:subscription, subscriber: user, stripe_id: 'sub_foo999')
      end

      it 'does not create a new subscription' do
        expect { do_get }.not_to change(Subscription, :count)
      end
    end

    context 'when subscription already exists but for another user' do
      before do
        create(:subscription, subscriber: create(:user), stripe_id: 'sub_foo999')
      end

      it 'raises an error' do
        expect { do_get }.to raise_error(/Stripe ID has already been taken/)
      end
    end

    context 'when redemption mode is set to self' do
      before do
        params[:redemption_mode] = CheckoutService::REDEMPTION_MODE_SELF
      end

      it 'sets subscription user as the redeemer' do
        expect { do_get }.to change(Subscription, :count).by(1)
        expect(Subscription.last.redeemer).to eq(user)
      end
    end
  end
end
