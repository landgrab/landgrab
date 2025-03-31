# frozen_string_literal: true

RSpec.describe Admin::SubscriptionsController do
  render_views

  let(:subscription) { create(:subscription, subscriber:, redeemer:) }

  describe 'PATCH subscriptions#update' do
    subject(:do_patch) do
      patch :update, params: { id: subscription.hashid, subscription: subscription_params }
    end

    let(:auth_user) { create(:user, admin: true) }
    let(:tile) { create(:tile) }
    let(:another_tile) { create(:tile) }

    let(:subscription_params) { {} }

    let(:subscriber) { create(:user) }
    let(:redeemer) { create(:user) }

    before do
      sign_in(auth_user, scope: :user)
    end

    context 'when not an admin' do
      before do
        auth_user.update!(admin: false)
      end

      it 'returns not found error' do
        do_patch

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when logged out' do
      before do
        sign_out(auth_user)
      end

      it 'redirects to login' do
        do_patch

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it 'updates the subscription subscriber' do
      subscription_params[:subscriber_id] = redeemer.hashid

      expect { do_patch }.to change { subscription.reload.subscriber_id }.from(subscriber.id).to(redeemer.id)
    end

    it 'updates the subscription redeemer' do
      subscription_params[:redeemer_id] = subscriber.hashid

      expect { do_patch }.to change { subscription.reload.redeemer_id }.from(redeemer.id).to(subscriber.id)
    end

    it 'updates the subscription tile' do
      subscription_params[:tile_id] = tile.hashid

      expect { do_patch }.to change { subscription.reload.tile_id }.from(nil).to(tile.id)
    end

    it 'sets the latest_subscription on newly assigned tile' do
      subscription_params[:tile_id] = tile.hashid

      expect { do_patch }.to change { tile.reload.latest_subscription_id }.from(nil).to(subscription.id)
    end

    context 'when setting a tile that is already linked to another subscription' do
      let(:other_subscription) { create(:subscription, tile:) }

      before do
        other_subscription
        subscription_params[:tile_id] = tile.hashid
      end

      it 'does not update the subscription tile' do
        expect { do_patch }.not_to(change { subscription.reload.tile_id })
      end

      it 'returns an error' do
        do_patch

        expect(response.body).to include('Tile is unavailable')
      end

      it 'allows update if the other subscription was cancelled' do
        other_subscription.update!(stripe_status: :canceled)

        expect { do_patch }.to(change { subscription.reload.tile_id })
      end
    end

    context 'when unsetting the tile for which this subscription was the latest_subscription' do
      before do
        subscription.update!(tile:)
        subscription_params[:tile_id] = nil
        tile.update!(latest_subscription: subscription)
      end

      it 'wipes the subscription tile' do
        expect { do_patch }.to(change { subscription.reload.tile_id }.from(tile.id).to(nil))
      end

      it 'wipes the latest_subscription value on the tile' do
        expect { do_patch }.to(change { tile.reload.latest_subscription_id }.from(subscription.id).to(nil))
      end

      it 'sets the latest_subscription on the wiped tile to the next latest associated subscription' do
        another_subscription = create(:subscription, tile:)
        subscription_params[:tile_id] = nil
        tile.update!(latest_subscription: subscription)

        expect { do_patch }.to(change { tile.reload.latest_subscription_id }.from(subscription.id).to(another_subscription.id))
      end
    end

    context 'when changing the tile from one where this subscription was the latest_subscription' do
      before do
        another_tile
        subscription.update!(tile:)
        subscription_params[:tile_id] = another_tile.hashid
        tile.update!(latest_subscription: subscription)
      end

      it 'assigns new subscription tile' do
        expect { do_patch }.to(change { subscription.reload.tile_id }.from(tile.id).to(another_tile.id))
      end

      it 'wipes the latest_subscription value on the old tile' do
        expect { do_patch }.to(change { tile.reload.latest_subscription_id }.from(subscription.id).to(nil))
      end

      it 'sets the latest_subscription value on the new tile' do
        expect { do_patch }.to(change { another_tile.reload.latest_subscription_id }.from(nil).to(subscription.id))
      end
    end
  end
end
