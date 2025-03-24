# frozen_string_literal: true

RSpec.describe SubscriptionsController do
  describe 'DELETE subscriptions#cancel' do
    subject(:do_delete) do
      delete :cancel, id: subscription.hashid
    end

    let(:user) { create(:user, stripe_customer_id: 'cus_0123456789') }
    let(:subscription) { create(:subscription, subscriber: user)}

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
        do_delete

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it 'redirects to the Stripe billing portal url' do
      do_delete

      expect(response).to redirect_to('https://billing.stripe.com/p/session/test_9999999999')
    end

    it 'generates a session using user stripe id and flow data' do
      do_delete

      expect(Stripe::BillingPortal::Session).to have_received(:create).with(
        hash_including(
          customer: user.stripe_customer_id,
          flow_data: hash_including(
            type: :subscription_cancel,
            subscription: hash_including(subscription.stripe_id)
          )
        )
      )
    end

    context 'with a subscription subscribed by another user' do
      before do
        subscription.update(subscriber: create(:user))
      end

      it 'returns a not found error' do
        expect(do_delete).to have_http_status(:not_found)
      end
    end
  end
end
