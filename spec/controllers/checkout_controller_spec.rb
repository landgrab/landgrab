# frozen_string_literal: true

RSpec.describe CheckoutController do
  render_views

  let(:user) { create(:user, stripe_customer_id: "cus_#{rand(999_999)}") }
  let(:project) { create(:project) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('STRIPE_PUBLISHABLE_KEY').and_return('pk_test_123456')
  end

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

      it 'redirects to registration page' do
        get :checkout, params: { price: price.hashid }

        expect(response).to redirect_to(new_user_registration_path)
        expect(flash[:notice]).to include('Please register')
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

    it 'creates a checkout session with tile subscription metadata' do
      tile = create(:tile)

      get :checkout, params: { price: price.hashid, tile: tile.hashid }

      expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(subscription_data: { metadata: hash_including(tile: tile.hashid) }))
    end

    it 'creates a checkout session with redemption_mode subscription metadata' do
      get :checkout, params: { price: price.hashid, redemption_mode: 'self' }

      expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(subscription_data: { metadata: hash_including(redemption_mode: 'self') }))
    end
  end
end
