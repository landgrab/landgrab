# frozen_string_literal: true

RSpec.describe StaticPagesController do
  describe 'GET static_pages#my_tile' do
    subject(:do_get) do
      get :my_tile
    end

    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, subscriber: user) }
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

    context 'with no tile' do
      it 'redirects to homepage' do
        do_get

        expect(response).to redirect_to(root_path)
      end
    end

    context 'with a tile subscribed by current user' do
      before do
        subscription.update!(tile:)
      end

      it 'redirects to the tile' do
        do_get

        expect(response).to redirect_to(tile_path(tile))
      end
    end
  end
end
