# frozen_string_literal: true

RSpec.describe ProjectsController do
  render_views

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:plot) { create(:plot, project:) }
  let(:tile) { create(:tile, plot:) }

  describe 'GET projects#show' do
    subject(:do_get) do
      get :show, params: { id: project.hashid }
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

      it 'shows the project details anyway' do
        do_get

        expect(response.body).to include(project.title)
      end
    end

    context 'when not subscribed to a tile and no tiles available' do
      before do
        plot
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows the project details' do
        do_get

        expect(response.body).to include(project.title)
      end

      it 'shows the plot details' do
        do_get

        expect(response.body).to include(plot.title)
      end

      it 'shows option to subscribe to the project' do
        do_get

        expect(response.body).to include('There are no tiles available')
      end
    end

    context 'when not subscribed but tiles available' do
      before do
        tile
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows the project details' do
        do_get

        expect(response.body).to include(project.title)
      end
    end

    context 'when subscription is redeemed in current project' do
      before do
        create(:subscription, redeemer: user)
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows a prompt to choose a tile' do
        do_get

        expect(response.body).to include('need to choose a tile')
      end
    end
  end
end
