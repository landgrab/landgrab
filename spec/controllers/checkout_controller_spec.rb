# frozen_string_literal: true

RSpec.describe CheckoutController do
  render_views

  let(:user) { create(:user, stripe_customer_id: "cus_#{rand(999_999)}") }
  let(:project) { create(:project) }

  describe 'GET checkout#generate' do
    let(:price) { create(:price) }

    it 'redirects to the checkout page' do
      get :generate, params: { price: price.hashid }

      expect(response).to redirect_to(checkout_checkout_url(price: price.hashid))
    end
  end

  describe 'GET checkout#checkout' do
    let(:promo_code) { create(:promo_code) }
    let(:price) { create(:price) }

    before do
      sign_in(user)

      stub_stripe_api(:post, 200, 'checkout/sessions', 'checkout_sessions/new')

      allow(Stripe::Checkout::Session).to receive(:create).and_call_original
    end

    context 'when user is logged out' do
      before do
        sign_out(user)
      end

      it 'redirects to the login page' do
        get :checkout

        expect(response).to redirect_to(new_user_session_url)
      end
    end

    context 'when user is not stripe enrolled' do
      before do
        user.update!(stripe_customer_id: nil)

        stub_stripe_api(:get, 200, 'customers/search', 'customers/search/empty', "query=email:'#{user.email}'")
        stub_stripe_api(:post, 200, 'customers', 'customers/create')
      end

      it 'enrols customer with Stripe' do
        get :checkout, params: { price: price.hashid }

        expect(user.reload.stripe_customer_id).to eq 'cus_aoeuidhtns'
      end
    end

    it 'returns success response with stripe javascript' do
      get :checkout, params: { price: price.hashid }

      # raise response.body

      expect(response).to be_successful
      expect(response.body).to include('js.stripe.com')
    end

    it 'creates a checkout session with price specified' do
      get :checkout, params: { price: price.hashid }

      expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(line_items: [{ price: price.stripe_id, quantity: 1 }]))
    end

    it 'creates a checkout session with supplied promo code specified' do
      get :checkout, params: { price: price.hashid, code: promo_code.code }

      expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(discounts: [{ promotion_code: promo_code.stripe_id }]))
    end
  end

  describe 'GET checkout#success' do
    let(:cs_body) do
      stripe_fixture('checkout_sessions/complete').tap do |x|
        x[:customer] = user.stripe_customer_id
      end
    end

    before do
      sign_in(user)

      stub_stripe_api(:get, 200, 'checkout/sessions/cs_test_abc123', cs_body)

      allow(Stripe::Checkout::Session).to receive(:retrieve).and_call_original
      allow(StripeSubscriptionRefreshJob).to receive(:perform_later)
    end

    it 'retrieves the checkout session data' do
      get :success, params: { session_id: 'cs_test_abc123', project: project.hashid }

      expect(Stripe::Checkout::Session).to have_received(:retrieve).with('cs_test_abc123')
    end

    it 'redirects to project page with flash message' do
      get :success, params: { session_id: 'cs_test_abc123', project: project.hashid }

      expect(response).to redirect_to(project_path(project))
      expect(flash[:success]).to include('Your subscription has been successfully set up!')
    end

    it 'creates a subscription for the user' do
      expect do
        get :success, params: { session_id: 'cs_test_abc123', project: project.hashid }
      end.to change(Subscription, :count).by(1)
    end

    it 'queues a subscription refresh job' do
      get :success, params: { session_id: 'cs_test_abc123', project: project.hashid }

      expect(StripeSubscriptionRefreshJob).to have_received(:perform_later)
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
        get :success, params: { session_id: 'cs_test_abc123', project: project.hashid }

        expect(response).to redirect_to(checkout_checkout_url)
        expect(flash[:danger]).to include('try again')
      end
    end

    context 'when subscription customer id mismatches current user' do
      before do
        user.update!(stripe_customer_id: 'cus_somethingelse')
      end

      it 'raises an error' do
        expect do
          get :success, params: { session_id: 'cs_test_abc123', project: project.hashid }
        end.to raise_error(/Stripe Customer ID mismatch/)
      end
    end

    context 'when subscription already exists for this user' do
      before do
        create(:subscription, subscriber: user, stripe_id: 'sub_foo999')
      end

      it 'does not create a new subscription' do
        expect do
          get :success, params: { session_id: 'cs_test_abc123', project: project.hashid }
        end.not_to change(Subscription, :count)
      end
    end

    context 'when subscription already exists but for another user' do
      before do
        create(:subscription, subscriber: create(:user), stripe_id: 'sub_foo999')
      end

      it 'raises an error' do
        expect do
          get :success, params: { session_id: 'cs_test_abc123', project: project.hashid }
        end.to raise_error(/Stripe ID has already been taken/)
      end
    end
  end
end
