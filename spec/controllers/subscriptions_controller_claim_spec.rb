# frozen_string_literal: true

RSpec.describe SubscriptionsController do
  render_views

  describe 'GET subscriptions#claim' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:subscription) { create(:subscription, claim_hash: 'valid-claim-hash') }

    before do
      sign_in(user)
    end

    context 'when logged out' do
      before do
        sign_out(user)
      end

      it 'redirects to registration' do
        get :claim, params: { id: subscription.hashid }

        expect(response).to redirect_to(new_user_registration_path)
      end
    end

    context 'with a valid claim hash' do
      before do
        subscription
        project
      end

      it 'assigns user to the subscription and redirects to welcome page' do
        get :claim, params: { id: subscription.hashid, hash: 'valid-claim-hash' }

        expect(response).to redirect_to(welcome_project_path(project))
        expect(subscription.reload.subscriber).to eq(user)
      end

      it 'silently passes if already claimed by user' do
        get :claim, params: { id: subscription.hashid, hash: 'valid-claim-hash' }

        expect(response).to redirect_to(welcome_project_path(project))
      end

      it 'rejects if already claimed by another user' do
        subscription.update!(subscriber: create(:user))

        get :claim, params: { id: subscription.hashid, hash: 'valid-claim-hash' }

        expect(response).to redirect_to(support_path)
        expect(flash[:danger]).to include('different account')
      end
    end

    context 'with a missing claim hash' do
      before do
        subscription
      end

      it 'returns error and redirects to support' do
        get :claim, params: { id: subscription.hashid }

        expect(flash[:danger]).to include('link is missing something')
        expect(response).to redirect_to(support_path)
      end
    end

    context 'with an invalid claim hash' do
      before do
        subscription
      end

      it 'returns error and redirects to support' do
        get :claim, params: { id: subscription.hashid, hash: 'not-valid' }

        expect(flash[:danger]).to include("link doesn't look quite right")
        expect(response).to redirect_to(support_path)
      end
    end
  end
end
