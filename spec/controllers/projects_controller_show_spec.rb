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

    context 'when the project has plots with tiles' do
      before do
        create(:tile, plot: create(:plot, project:, title: 'Meadow'))
      end

      it 'totals the plots and tiles' do
        do_get

        expect(response.parsed_body.css('.fs-3').map(&:text)).to eq(%w[1 1 1])
      end

      it 'outlines the plots for the plot overview, labelled with available tiles' do
        do_get

        plots = JSON.parse(response.parsed_body.at_css('[data-plots]')['data-plots'])
        expect(plots.map { |plot| plot['properties']['label'] }).to eq(['Meadow: 1 available tile'])
      end

      it "shows each plot's available tiles out of its total" do
        woodland = create(:plot, project:, title: 'Woodland', polygon: 'POLYGON ((0.01 51.5, 0.011 51.5, 0.011 51.501, 0.01 51.501, 0.01 51.5))')
        create(:subscription, tile: create(:tile, plot: woodland))
        do_get

        expect(response.parsed_body.css('.card-text').map { |text| text.text.squish })
          .to eq(['1 of 1 tiles available', 'There are no tiles available'])
      end

      it 'links to the tile search' do
        do_get

        expect(response.body).to include(find_tile_project_path(project))
      end

      it 'no longer features any plots' do
        do_get

        expect(response.body).not_to include('Featured Plot')
      end
    end

    context 'when the project has no tiles' do
      before { plot }

      it 'shows no map' do
        do_get

        expect(response.parsed_body.at_css('[data-plots]')).to be_nil
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
