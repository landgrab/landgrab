# frozen_string_literal: true

RSpec.describe TileMap do
  let(:viewer) { create(:user) }
  let(:profile_user) { create(:user, first_name: 'Ollie') }
  let(:stranger) { create(:user) }
  let(:plot) { create(:plot) }

  def tile_subscribed(subscriber:, redeemer:)
    create(:tile, plot:).tap do |tile|
      create(:subscription, tile:, subscriber:, redeemer:)
      tile.reload
    end
  end

  def build_map(**options)
    described_class.new(highlighter: TileHighlightService.new(viewer:, subject: profile_user), **options)
  end

  describe '#tiles' do
    it 'fills tiles by category and availability' do
      gifted = tile_subscribed(subscriber: profile_user, redeemer: stranger)
      taken = tile_subscribed(subscriber: stranger, redeemer: stranger)
      available = create(:tile, plot:)

      colours = build_map(tiles: [gifted, taken, available]).tiles.index_with(&:map_colour)

      expect(colours).to eq(gifted => TileMap::LIME, taken => TileMap::RED, available => TileMap::GREEN)
    end

    it 'gives my tile an emerald border and draws it last' do
      mine = tile_subscribed(subscriber: viewer, redeemer: viewer)
      available = create(:tile, plot:)

      tiles = build_map(tiles: [mine, available]).tiles

      expect(tiles.last).to eq(mine)
      expect([mine.map_colour, mine.map_border]).to eq([TileMap::ORANGE, TileMap::EMERALD])
    end

    it 'gives focus tiles a white border, even when they are mine' do
      mine = tile_subscribed(subscriber: viewer, redeemer: viewer)

      build_map(tiles: [], focus_tiles: [mine]).tiles

      expect(mine.map_border).to eq(TileMap::WHITE)
    end

    it 'adds highlighted tiles in the plot that were not asked for' do
      redeemed = tile_subscribed(subscriber: profile_user, redeemer: profile_user)

      expect(build_map(tiles: [], plot:).tiles).to contain_exactly(redeemed)
    end

    it 'adds nothing without a plot' do
      tile_subscribed(subscriber: profile_user, redeemer: profile_user)

      expect(build_map(tiles: []).tiles).to be_empty
    end
  end

  describe '#legend' do
    let(:referred_user) { create(:user, referrer: profile_user) }

    it 'lists only categories on the map, in order, with the profile user\'s name' do
      available = create(:tile, plot:)
      tiles = [available, tile_subscribed(subscriber: viewer, redeemer: viewer), tile_subscribed(subscriber: stranger, redeemer: profile_user)]
      tiles += Array.new(2) { tile_subscribed(subscriber: referred_user, redeemer: stranger) }

      titles = build_map(tiles:, focus_tiles: [available]).legend.pluck(:title)

      expect(titles).to eq(['My tile', "Ollie's tile", "Ollie's referred tiles", 'This tile', 'Available'])
    end

    it 'says "My" when the viewer is the subject' do
      tile = tile_subscribed(subscriber: viewer, redeemer: stranger)
      map = described_class.new(tiles: [tile], highlighter: TileHighlightService.new(viewer:))

      expect(map.legend.pluck(:title)).to eq(['My gifted tile'])
    end

    it 'names team tiles after the team' do
      team = create(:team, title: 'Acme')
      tiles = Array.new(2) { tile_subscribed(subscriber: stranger, redeemer: create(:user, team:)) }
      map = described_class.new(tiles:, highlighter: TeamTileHighlightService.new(viewer:, team:))

      expect(map.legend).to eq([{ key: :team, title: 'Acme tiles', fill: TileMap::ORANGE, border: nil }])
    end
  end
end
