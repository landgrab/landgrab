# frozen_string_literal: true

RSpec.describe SubscriptionsController do
  render_views

  describe 'GET subscriptions#show' do
    subject(:do_get) do
      get :show, params: { id: subscription.hashid }
    end

    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, subscriber: user, redeemer: user) }
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

    context 'with an unredeemed subscription' do
      before do
        subscription.update(redeemer: nil)
      end

      it 'shows redemption invite form' do
        do_get

        expect(response.body).to include('Recipient name')
      end
    end

    context 'with a non-linked subscription' do
      before do
        subscription
        project
      end

      it 'displays an option to choose a project tile' do
        do_get

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('find any tile')
      end
    end

    context 'with an associated tile' do
      before do
        subscription.update!(tile:)
      end

      it 'displays a link to the tile' do
        do_get

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(tile.w3w)
        expect(response.body).to include(tile_path(tile))
      end
    end

    context 'with a cancelled subscription' do
      before do
        subscription.update!(stripe_status: 'canceled') # EN-US spelling :facepalm:
      end

      it 'displays a message that the subscription is cancelled (with two Ls)' do
        do_get

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('subscription is cancelled') # EN-GB spelling :party:
      end
    end
  end
end
