# frozen_string_literal: true

RSpec.describe SubscriptionsController do
  render_views

  describe 'GET /subscriptions' do
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
        get :index

        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context 'with a non-redeemed subscription' do
      before do
        subscription
        project
      end

      it 'displays an option to choose a project tile' do
        get :index

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Find a tile')
        expect(response.body).to include(welcome_project_path(project))
      end
    end

    context 'with a redeemed subscription' do
      before do
        subscription.update!(tile:)
      end

      it 'displays a link to the tile' do
        get :index

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("///#{tile.w3w}")
        expect(response.body).to include(tile_path(tile))
      end
    end
  end
end
