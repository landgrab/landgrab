# frozen_string_literal: true

RSpec.describe TilesController do
  render_views

  describe 'GET tiles#show' do
    subject(:do_get) do
      get :show, params: { id: tile.hashid }
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

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows login link' do
        do_get

        expect(response.body).to include(new_user_session_path)
      end

      it 'shows the tile details anyway' do
        do_get

        expect(response.body).to include(tile.w3w)
      end
    end

    context 'with an available tile' do
      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows the tile' do
        do_get

        expect(response.body).to include(tile.w3w)
      end
    end

    context 'with a tile subscribed by current user' do
      before do
        subscription.update!(tile:)
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows the tile' do
        do_get

        expect(response.body).to include(tile.w3w)
      end

      it 'shows a message that the tile is yours' do
        do_get

        expect(response.body).to include('Your subscription to this tile')
      end
    end

    context 'with a tile subscribed by another user' do
      before do
        subscription.update!(subscriber: create(:user), tile:)
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows the tile' do
        do_get

        expect(response.body).to include(tile.w3w)
      end

      it 'shows a message that the tile is unavailable' do
        do_get

        expect(response.body).to include('Someone has already subscribed to this tile.')
      end
    end

    context 'with a tile with unowned subscription' do
      before do
        subscription.update!(subscriber: nil, tile:)
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows the tile' do
        do_get

        expect(response.body).to include(tile.w3w)
      end

      it 'shows a message that the tile is unavailable' do
        do_get

        expect(response.body).to include('Someone has already subscribed to this tile.')
      end
    end
  end

  describe 'GET tiles#embed' do
    let(:tile) { create(:tile) }

    it 'hides the legend by default' do
      get :embed, params: { id: tile.hashid }

      expect(response.body).to include('data-tiles=')
      expect(response.body).not_to include('tile-legend')
    end

    it 'shows the legend in a banner with legend=1' do
      get :embed, params: { id: tile.hashid, legend: '1' }

      expect(response.parsed_body.at_css('.map-legend-banner .tile-legend')).to be_present
    end

    it 'hides the legend with legend=0' do
      get :embed, params: { id: tile.hashid, legend: '0' }

      expect(response.body).not_to include('tile-legend')
    end
  end
end
