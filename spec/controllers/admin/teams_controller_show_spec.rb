# frozen_string_literal: true

RSpec.describe Admin::TeamsController do
  render_views

  let(:admin) { create(:user, admin: true) }
  let(:team) { create(:team, title: 'Acme') }

  before { sign_in(admin, scope: :user) }

  describe 'GET show' do
    subject(:do_get) { get :show, params: { id: team.slug } }

    it 'says when the team has no tiles' do
      do_get

      expect(response.body).to include('No tiles yet.')
    end

    context 'when a member redeems a tile' do
      before do
        member = create(:user, team:)
        create(:subscription, tile: create(:tile, plot: create(:plot, title: 'Meadow')), subscriber: member, redeemer: member)
      end

      it 'shows the team map with its plot overview' do
        do_get

        expect(response.body).to include('Acme has 1 tile across 1 plot.').and include('tile-legend')
        plots = JSON.parse(response.parsed_body.at_css('[data-plots]')['data-plots'])
        expect(plots.map { |plot| plot['properties']['label'] }).to eq(['Meadow: 1 team tile'])
      end
    end

    it 'rejects if not admin' do
      admin.update!(admin: false)

      do_get

      expect(response).to have_http_status(:not_found)
    end
  end
end
