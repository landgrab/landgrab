# frozen_string_literal: true

RSpec.describe PlotsController do
  render_views

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:plot) { create(:plot) }
  let(:tile) { create(:tile, plot:) }

  describe 'GET plots#show' do
    subject(:do_get) do
      get :show, params: { id: plot.hashid }
    end

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

      it 'shows the plot details anyway' do
        do_get

        expect(response.body).to include(plot.title)
      end
    end

    context 'when not subscribed to a tile' do
      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows the plot details' do
        do_get

        expect(response.body).to include(plot.title)
      end

      it 'shows option to subscribe to the plot' do
        do_get

        expect(response.body).to match(/Click an available tile .+ to subscribe/)
      end
    end

    context 'when subscribed to tile in current plot' do
      let(:subscription) { create(:subscription, subscriber: user, tile:) }

      before do
        subscription
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'mentions the tile' do
        do_get

        expect(response.body).to include(tile.w3w)
      end

      it 'shows a message that you are subscribed' do
        do_get

        expect(response.body).to include('already subscribed to a tile in this plot')
      end
    end
  end
end
