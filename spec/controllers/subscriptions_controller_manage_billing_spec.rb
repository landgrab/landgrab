# frozen_string_literal: true

RSpec.describe SubscriptionsController do
  describe 'POST subscriptions#manage_billing' do
    subject(:do_post) do
      post :manage_billing
    end

    let(:user) { create(:user, stripe_customer_id: 'cus_0123456789') }

    before do
      sign_in(user)

      stub_stripe_api(:post, 200, 'billing_portal/sessions', 'billing_portal_sessions/new')

      allow(Stripe::BillingPortal::Session).to receive(:create).and_call_original
    end

    context 'when logged out' do
      before do
        sign_out(user)
      end

      it 'redirects to login' do
        do_post

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it 'redirects to the Stripe billing portal url' do
      do_post

      expect(response).to redirect_to('https://billing.stripe.com/p/session/test_9999999999')
    end

    it 'generates a session using stripe id for current user' do
      do_post

      expect(Stripe::BillingPortal::Session).to have_received(:create).with(
        hash_including(customer: user.stripe_customer_id)
      )
    end
  end
end
