# frozen_string_literal: true

RSpec.describe SubscriptionsController do
  render_views

  describe 'GET subscriptions#redeem' do
    subject(:do_post) do
      post :redeem, params: { id: subscription.hashid, tile: tile.hashid }
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
        do_post

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with a non-redeemed subscription' do
      it 'connects tile to subscription' do
        do_post

        expect(response).to redirect_to(tile_path(tile))
        expect(flash[:notice]).to include("You've connected to this tile")
        expect(subscription.reload.tile).to eq(tile)
      end

      it 'assigns current user as the redeemer' do
        do_post

        expect(subscription.reload.redeemer).to eq(user)
      end
    end

    context 'when subscription was redeemed against another tile' do
      let(:alt_tile) { create(:tile) }

      before do
        subscription.update!(tile: alt_tile)
      end

      it 'notifies that subscription already used' do
        do_post

        expect(flash[:danger]).to include("already redeemed against another tile: ///#{alt_tile.w3w}")
      end
    end

    context 'when tile already redeemed by current user' do
      before do
        subscription.update!(tile:, redeemer: user)
      end

      it 'notifies that already redeemed' do
        do_post

        expect(flash[:notice]).to include("you're already connected to this tile")
        expect(response).to redirect_to(tile_path(tile))
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
