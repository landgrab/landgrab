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
        expect(flash[:notice]).to include('now subscribed to this tile')
        expect(subscription.reload.tile).to eq(tile)
      end
    end

    context 'when tile already redeemed by current user' do
      before do
        subscription.update!(tile:, subscriber: user)
      end

      it 'notifies that already redeemed' do
        do_post

        expect(flash[:notice]).to include("you're already subscribed to this tile")
        expect(response).to redirect_to(tile_path(tile))
      end
    end

    context 'when tile already redeemed by another user' do
      before do
        subscription
        create(:subscription, tile:, subscriber: create(:user))
      end

      it 'prevents redeeming' do
        do_post

        expect(flash[:danger]).to include('already been claimed by someone else')
        expect(response).to redirect_to(tile_path(tile))
        expect(subscription.reload.tile).to be_nil
      end
    end
  end
end
