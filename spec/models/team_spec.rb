# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team do
  describe '#team_tiles and #team_plots' do
    let(:team) { create(:team) }
    let(:member) { create(:user, team:) }
    let(:outsider) { create(:user) }
    let(:plot) { create(:plot) }
    let(:other_plot) { create(:plot, polygon: 'POLYGON ((0.01 51.5, 0.011 51.5, 0.011 51.501, 0.01 51.5))') }
    let!(:active) { tile_subscribed(redeemer: member) }
    let!(:trialing) { tile_subscribed(redeemer: member, stripe_status: 'trialing') }

    def tile_subscribed(redeemer:, stripe_status: 'active', tile_plot: plot)
      create(:tile, plot: tile_plot).tap do |tile|
        create(:subscription, tile:, subscriber: outsider, redeemer:, stripe_status:)
      end
    end

    before do
      tile_subscribed(redeemer: member, stripe_status: 'canceled', tile_plot: other_plot)
      tile_subscribed(redeemer: outsider, tile_plot: other_plot)
      create(:tile, plot: other_plot)
    end

    it 'includes only tiles members redeem through a usable subscription' do
      expect(team.team_tiles).to contain_exactly(active, trialing)
    end

    it 'lists only the plots containing team tiles' do
      expect(team.team_plots).to contain_exactly(plot)
    end
  end

  describe '#logo_for_display' do
    it 'returns the logo URL when set' do
      team = build(:team, logo_url: 'https://example.com/team-logo.png')

      expect(team.logo_for_display).to eq 'https://example.com/team-logo.png'
    end

    it 'returns a square logo placeholder when blank' do
      team = build(:team, logo_url: '')

      expect(team.logo_for_display).to eq 'https://placehold.co/400x400?text=Logo'
    end
  end
end
