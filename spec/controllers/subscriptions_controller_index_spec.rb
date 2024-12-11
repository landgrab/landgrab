# frozen_string_literal: true

RSpec.describe SubscriptionsController do
  render_views

  describe 'GET subscriptions#index' do
    subject(:do_get) do
      get :index
    end

    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, subscriber: user) }
    let(:project) { create(:project) }
    let(:tile) { create(:tile) }

    before do
      sign_in(user)
    end

    context 'when logged out' do
      before do
        sign_out(user)
      end

      it 'redirects to login' do
        do_get

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with a redeemed but unlinked subscription' do
      before do
        subscription.update!(redeemer: user)
        project
      end

      it 'displays the unallocated subscription' do
        do_get

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Unallocated subscription')
        expect(response.body).to include(subscription_path(subscription))
      end
    end

    context 'with a redeemed subscription' do
      before do
        subscription.update!(tile:)
      end

      it 'displays a link to the tile' do
        do_get

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("///#{tile.w3w}")
      end
    end
  end
end
