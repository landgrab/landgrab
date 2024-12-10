# frozen_string_literal: true

RSpec.describe SubscriptionsController do
  render_views

  describe 'POST subscriptions#link_tile' do
    subject(:do_post) do
      post :link_tile, params: { id: subscription.hashid, tile_hashid: tile.hashid }
    end

    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, subscriber: user) }
    let(:tile) { create(:tile) }

    before do
      sign_in(user)
    end

    it 'links to tile to the subscription' do
      expect { do_post }.to change { subscription.reload.tile }.to(tile)
    end

    it 'redirects to the tile' do
      do_post

      expect(response).to redirect_to(tile_path(tile))
    end

    context 'when logged out' do
      before do
        sign_out(user)
      end

      it 'redirects to login' do
        do_post

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when subscription was already redeemed against another tile' do
      let(:alt_tile) { create(:tile) }

      before do
        subscription.update!(tile: alt_tile)
      end

      it 'does not update the subscription tile' do
        expect { do_post }.not_to change { subscription.reload.tile }.from(tile)
      end

      it 'returns an error showing which tile is linked already' do
        do_post

        expect(flash[:danger]).to include("already linked to another tile: ///#{alt_tile.w3w}")
      end
    end

    context 'when tile already redeemed by another user' do
      before do
        subscription
        create(:subscription, tile:, redeemer: create(:user))
      end

      it 'prevents redeeming' do
        do_post

        expect(flash[:danger]).to include('already been redeemed by someone else')
        expect(response).to redirect_to(tile_path(tile))
        expect(subscription.reload.tile).to be_nil
        expect(subscription.reload.redeemer).to be_nil
      end
    end

    context 'when subscription was subscribed by a different user' do
      before do
        subscription.update!(subscriber: create(:user))
      end

      it 'returns warning message' do
        do_post

        expect(flash[:danger]).to include('you can only redeem your own subscriptions')
        expect(response).to redirect_to(tile_path(tile))
      end
    end
  end
end
