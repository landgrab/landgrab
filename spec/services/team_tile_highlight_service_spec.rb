# frozen_string_literal: true

RSpec.describe TeamTileHighlightService do
  subject(:service) { described_class.new(viewer:, team:) }

  let(:team) { create(:team, title: 'Acme') }
  let(:member) { create(:user, team:) }
  let(:viewer) { create(:user) }
  let(:stranger) { create(:user) }
  let(:plot) { create(:plot) }

  def tile_subscribed(redeemer:, subscriber: stranger, stripe_status: 'active', tile_plot: plot)
    create(:tile, plot: tile_plot).tap do |tile|
      create(:subscription, tile:, subscriber:, redeemer:, stripe_status:)
      tile.reload
    end
  end

  describe '#category_for' do
    it 'marks a tile a member redeems as team, whoever pays' do
      expect(service.category_for(tile_subscribed(redeemer: member))).to eq(:team)
    end

    it 'does not mark a tile a member only pays for' do
      expect(service.category_for(tile_subscribed(subscriber: member, redeemer: stranger))).to be_nil
    end

    it 'marks a tile the viewer redeems as mine, even when they are a member' do
      viewer.update!(team:)

      expect(service.category_for(tile_subscribed(redeemer: viewer))).to eq(:mine)
    end

    it 'ignores subscriptions that are not usable' do
      expect(service.category_for(tile_subscribed(redeemer: member, stripe_status: 'canceled'))).to be_nil
    end

    it 'marks only the team when signed out' do
      signed_out = described_class.new(viewer: nil, team:)

      expect(signed_out.category_for(tile_subscribed(redeemer: member))).to eq(:team)
    end
  end

  describe '#highlighted_tiles' do
    let!(:team_tile) { tile_subscribed(redeemer: member) }
    let!(:mine) { tile_subscribed(redeemer: viewer) }
    let!(:other_plot_tile) { tile_subscribed(redeemer: member, tile_plot: create(:plot, polygon: 'POLYGON ((0.01 51.5, 0.011 51.5, 0.011 51.501, 0.01 51.5))')) }

    before { tile_subscribed(redeemer: stranger) }

    it 'returns the team\'s and the viewer\'s tiles' do
      expect(service.highlighted_tiles).to contain_exactly(team_tile, mine, other_plot_tile)
    end

    it 'limits to a plot' do
      expect(service.highlighted_tiles(plot:)).to contain_exactly(team_tile, mine)
    end
  end

  describe '#label' do
    it 'names team tiles after the team' do
      expect([service.label(:team, 1), service.label(:team, 3)]).to eq(['Acme tile', 'Acme tiles'])
    end
  end
end
