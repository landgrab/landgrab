# frozen_string_literal: true

RSpec.describe TeamsController do
  render_views

  let(:team) { create(:team, title: 'Acme') }

  def subscribe(redeemer:, plot:)
    create(:subscription, tile: create(:tile, plot:), subscriber: redeemer, redeemer:)
  end

  def square_polygon(offset)
    lng = offset * 0.01
    "POLYGON ((#{lng} 51.5, #{lng + 0.001} 51.5, #{lng + 0.001} 51.501, #{lng} 51.501, #{lng} 51.5))"
  end

  describe 'GET teams#show' do
    subject(:do_get) { get :show, params: { id: team.slug } }

    it 'says when the team has no tiles' do
      do_get

      expect(response.body).to include('No tiles yet.')
    end

    context 'when members redeem tiles' do
      before do
        member = create(:user, team:)
        subscribe(redeemer: member, plot: create(:plot, title: 'Meadow', polygon: square_polygon(0)))
        subscribe(redeemer: member, plot: create(:plot, title: 'Woodland', polygon: square_polygon(1)))
        subscribe(redeemer: create(:user), plot: create(:plot, title: 'Elsewhere', polygon: square_polygon(2)))
      end

      it 'summarises the team tiles and shows them on a map with a legend' do
        do_get

        expect(response.body).to include('Acme has 2 tiles across 2 plots.')
          .and include('Acme tiles')
          .and include('tile-legend')
      end

      it 'outlines only the team plots for the plot overview' do
        do_get

        plots = JSON.parse(response.parsed_body.at_css('[data-plots]')['data-plots'])
        expect(plots.map { |plot| plot['properties']['label'] }).to eq(['Meadow: 1 team tile', 'Woodland: 1 team tile'])
      end
    end
  end

  describe 'GET teams#embed' do
    before { subscribe(redeemer: create(:user, team:), plot: create(:plot, polygon: square_polygon(0))) }

    it 'shows the same map without a legend' do
      get :embed, params: { id: team.slug }

      expect(response.body).to include('data-tiles=').and include('data-plots=')
      expect(response.body).not_to include('tile-legend')
    end

    it 'shows the legend in a banner when asked for' do
      get :embed, params: { id: team.slug, legend: '1' }

      expect(response.parsed_body.at_css('.map-legend-banner .tile-legend')).to be_present
    end

    it 'hides the legend when legend=0' do
      get :embed, params: { id: team.slug, legend: '0' }

      expect(response.body).not_to include('tile-legend')
    end
  end
end
