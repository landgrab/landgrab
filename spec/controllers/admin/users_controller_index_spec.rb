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

    context 'with first_name filter' do
      it 'includes user with matching first name' do
        get(:index, params: { first_name: user.first_name[0..2] })
        expect(response.body).to include(user.hashid)
      end

      it 'excludes user without matching first name' do
        get(:index, params: { first_name: 'nonmatching' })
        expect(response.body).not_to include(user.hashid)
      end
    end

    context 'with last_name filter' do
      it 'includes user with matching last name' do
        get(:index, params: { last_name: user.last_name[0..2] })
        expect(response.body).to include(user.hashid)
      end

      it 'excludes user without matching last name' do
        get(:index, params: { last_name: 'nonmatching' })
        expect(response.body).not_to include(user.hashid)
      end
    end

    context 'with email filter' do
      it 'includes user with matching email' do
        get(:index, params: { email: user.email[0..2] })
        expect(response.body).to include(user.hashid)
      end

      it 'excludes user without matching email' do
        get(:index, params: { email: 'nonmatching' })
        expect(response.body).not_to include(user.hashid)
      end
    end

    context 'with stripe_customer_id filter' do
      it 'includes user with matching stripe_customer_id' do
        get(:index, params: { stripe_customer_id: user.stripe_customer_id })
        expect(response.body).to include(user.hashid)
      end

      it 'excludes user without matching stripe_customer_id' do
        get(:index, params: { stripe_customer_id: 'nonmatching' })
        expect(response.body).not_to include(user.hashid)
      end
    end

    context 'with team filter' do
      let(:team) { create(:team) }

      before do
        user.update!(team: team)
      end

      it 'includes user with matching team' do
        get(:index, params: { team: team.hashid })
        expect(response.body).to include(user.hashid)
      end

      it 'excludes user without matching team' do
        other_team = create(:team)
        get(:index, params: { team: other_team.hashid })
        expect(response.body).not_to include(user.hashid)
      end
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
