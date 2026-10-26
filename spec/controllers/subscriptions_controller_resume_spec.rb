# frozen_string_literal: true

RSpec.describe SubscriptionsController do
  describe 'POST subscriptions#resume' do
    subject(:do_post) do
      post :resume, params: { id: subscription.hashid }
    end

    let(:user) { create(:user, stripe_customer_id: 'cus_abc123') }
    let(:subscription) { create(:subscription, subscriber: user, stripe_id: 'sub_123', stripe_status: 'paused') }
    let(:refreshed_status) { 'active' }

    before do
      sign_in(user)

      stub_stripe_api(:post, 200, 'subscriptions/sub_123/resume', 'subscriptions/success')
      stub_stripe_api(:get, 200, 'subscriptions/sub_123', stripe_fixture('subscriptions/success').merge(status: refreshed_status))

      allow(Stripe::Subscription).to receive(:resume).and_call_original
    end

    context 'when logged out' do
      before { sign_out(user) }

      it 'redirects to login' do
        do_post

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it 'resumes the subscription with a new billing cycle' do
      do_post

      expect(Stripe::Subscription).to have_received(:resume).with('sub_123', billing_cycle_anchor: 'now')
    end

    it 'refreshes the subscription status' do
      do_post

      expect(subscription.reload).to be_stripe_status_active
    end

    it 'redirects to the subscription with a success message' do
      do_post

      expect(response).to redirect_to(subscription)
      expect(flash[:success]).to include('resumed')
    end

    context 'when the subscription is still paused after resuming' do
      let(:refreshed_status) { 'paused' }

      it 'asks for a payment method' do
        do_post

        expect(flash[:danger]).to include('add a valid payment method')
      end
    end

    context 'when Stripe rejects the resume' do
      before do
        stub_stripe_api(:post, 400, 'subscriptions/sub_123/resume', { error: { type: 'invalid_request_error', message: 'No payment method' } })
      end

      it 'asks for a payment method' do
        do_post

        expect(flash[:danger]).to include('add a valid payment method')
      end

      it 'leaves the subscription paused' do
        do_post

        expect(subscription.reload).to be_stripe_status_paused
      end
    end

    context 'when the subscription is not paused' do
      let(:subscription) { create(:subscription, subscriber: user, stripe_id: 'sub_123', stripe_status: 'active') }

      it 'does not call Stripe' do
        do_post

        expect(Stripe::Subscription).not_to have_received(:resume)
      end
    end

    context 'when the user only redeemed (did not pay for) the subscription' do
      let(:subscription) { create(:subscription, subscriber: create(:user), redeemer: user, stripe_id: 'sub_123', stripe_status: 'paused') }

      it 'does not call Stripe' do
        do_post

        expect(Stripe::Subscription).not_to have_received(:resume)
      end
    end

    context 'with a subscription belonging to another user' do
      let(:subscription) { create(:subscription, subscriber: create(:user), stripe_status: 'paused') }

      it 'returns not found' do
        expect(do_post).to have_http_status(:not_found)
      end
    end
  end
end
