# frozen_string_literal: true

RSpec.describe RedemptionInvitesController do
  render_views

  describe 'GET redemption_invites#redeem' do
    subject(:do_get) do
      get :redeem, params:
    end

    let(:params) { { id: invite.hashid, token: invite.token } }
    let(:subscriber) { create(:user) }
    let(:user) { create(:user) }
    let(:invite) { create(:redemption_invite, subscription:) }
    let(:subscription) { create(:subscription, subscriber:) }
    let(:project) { create(:project) }

    before do
      sign_in(user)
    end

    context 'when logged out' do
      before do
        sign_out(user)
      end

      it 'redirects to registration with flash' do
        do_get

        expect(response).to redirect_to(new_user_registration_path)
        expect(flash[:notice]).to include('redeem')
      end
    end

    it 'assigns current user as the redeemer' do
      do_get

      expect(subscription.reload.redeemer).to eq(user)
    end

    context 'with incorrect token' do
      before do
        params[:token] = 'garbage'
      end

      it 'rejects request' do
        do_get

        expect(response).to redirect_to support_path
        expect(flash[:danger]).to include "link doesn't look quite right"
      end
    end

    context 'when the current user is the subscriber and self_redeem NOT set' do
      before do
        subscription.update!(subscriber: user)
      end

      it 'does not redeem the subscription' do
        expect { do_get }.not_to change { subscription.reload.redeemer }
      end

      it 'redirects to subscription page with warning' do
        do_get

        expect(response).to redirect_to(subscription_path(subscription))
        expect(flash[:notice]).to include('link is for sharing')
      end
    end

    context 'when the current user is the subscriber and self_redeem IS set' do
      before do
        subscription.update!(subscriber: user)
        params[:self_redeem] = '1'
      end

      it 'redeems the subscription' do
        expect { do_get }.to change { subscription.reload.redeemer }.to(user)
      end

      it 'redirects to subscription page with success message' do
        do_get

        expect(response).to redirect_to(subscription_path(subscription))
        expect(flash[:notice]).to include("you've redeemed this subscription")
      end
    end

    context 'when subscription was already redeemed by current user' do
      before do
        subscription.update!(redeemer: user)
      end

      it 'returns warning message' do
        do_get

        expect(flash[:notice]).to include('already linked to your account')
      end

      it 'redirects to the subscription page' do
        do_get

        expect(response).to redirect_to(subscription_path(subscription))
      end
    end

    context 'when subscription was subscribed by a different user' do
      before do
        subscription.update!(redeemer: create(:user))
      end

      it 'returns warning message' do
        do_get

        expect(flash[:danger]).to include('connected to a different account')
      end

      it 'redirects to support page' do
        do_get

        expect(response).to redirect_to(support_path)
      end
    end
  end
end
