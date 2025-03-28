# frozen_string_literal: true

RSpec.describe Admin::UsersController do
  render_views

  describe 'GET index' do
    let(:admin) { create(:user, admin: true) }
    let(:user) { create(:user) }

    before do
      sign_in(admin, scope: :user)

      user
    end

    it 'returns list of users' do
      get(:index)

      expect(response.body).to include(user.hashid)
    end

    it 'rejects if not admin' do
      admin.update!(admin: false)

      get(:index)

      expect(response).to have_http_status(:not_found)
    end

    context 'with redeemed_subscription_to_plot' do
      let(:plot) { create(:plot) }
      let(:tile) { create(:tile, plot: plot) }
      let(:subscription) { create(:subscription, tile: tile, redeemer: user) }

      before do
        subscription
      end

      it 'includes user who has redeemed a subscription to given plot' do
        get(:index, params: { redeemed_subscription_to_plot: [plot.hashid] })

        expect(response.body).to include(user.hashid)
      end

      it 'excludes users not subscribed' do
        subscription.destroy

        get(:index, params: { redeemed_subscription_to_plot: [plot.hashid] })

        expect(response.body).not_to include(user.hashid)
      end

      it 'excludes users with inactive subscriptions' do
        subscription.update!(stripe_status: 'canceled')

        get(:index, params: { redeemed_subscription_to_plot: [plot.hashid] })

        expect(response.body).not_to include(user.hashid)
      end
    end
  end
end
