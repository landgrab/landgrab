# frozen_string_literal: true

RSpec.describe TilesController do
  render_views

  describe 'GET tiles#show' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:subscription) { create(:subscription, subscriber: user) }
    let(:project) { create(:project) }
    let(:tile) { create(:tile) }

    before do
      sign_in(user)
      tile
    end

    context 'when logged out' do
      before do
        sign_out(user)
      end

      it 'returns a 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'shows login link' do
        get :show, params: { id: tile.hashid }

        expect(response.body).to include(new_user_session_path)
      end

      it 'shows the tile details anyway' do
        get :show, params: { id: tile.hashid }

        expect(response.body).to include(tile.w3w)
      end
    end

    context 'with an unclaimed tile' do
      it 'returns a 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'shows the tile' do
        get :show, params: { id: tile.hashid }

        expect(response.body).to include(tile.w3w)
      end
    end

    context 'with a tile subcribed by current user' do
      before do
        subscription.update!(tile:)
      end

      it 'returns a 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'shows the tile' do
        get :show, params: { id: tile.hashid }

        expect(response.body).to include(tile.w3w)
      end

      it 'shows a message that the tile is yours' do
        get :show, params: { id: tile.hashid }

        expect(response.body).to include('Your subscription to this tile')
      end
    end

    context 'with a tile subcribed by another user' do
      before do
        subscription.update!(subscriber: other_user, tile:)
      end

      it 'returns a 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'shows the tile' do
        get :show, params: { id: tile.hashid }

        expect(response.body).to include(tile.w3w)
      end

      it 'shows a message that the tile is already claimed' do
        get :show, params: { id: tile.hashid }

        expect(response.body).to include('already subscribed by someone else')
      end
    end
  end
end
