# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plot do
  let(:plot) { build(:plot) }

  it 'is valid by default' do
    expect(plot).to be_valid
  end

  it 'handles polygon centroid' do
    # See https://github.com/landgrab/landgrab/issues/1
    expect(plot.polygon.methods).to include :centroid
  end

  describe '#tiles_subscribed_by' do
    subject(:tiles_subscribed) { plot.tiles_subscribed_by(user) }

    let(:user) { create(:user) }
    let(:tile) { create(:tile, plot:) }
    let(:subscription) { create(:subscription, subscriber: user, tile:) }

    before { subscription }

    it 'returns subscribed tile' do
      expect(tiles_subscribed.ids).to contain_exactly(tile.id)
    end

    it 'excludes unsubscribed tiles' do
      subscription.destroy

      expect(tiles_subscribed.ids).to be_empty
    end

    it 'excludes tiles subscribed by another user' do
      subscription.update!(subscriber: create(:user))

      expect(tiles_subscribed.ids).to be_empty
    end
  end

  describe '#tiles_for_map' do
    subject(:tiles_for_map) { plot.tiles_for_map }

    let(:plot) { create(:plot) }
    let(:unavailable_tiles) { Array.new(3) { create(:subscription, tile: create(:tile, plot:)).tile } }
    let(:available_tiles) { create_list(:tile, 3, plot:) }

    before do
      stub_const('Plot::MAP_TILE_LIMIT', 4)
      stub_const('Plot::MAP_UNAVAILABLE_TILE_LIMIT', 2)
      unavailable_tiles
      available_tiles
      create(:tile, plot: create(:plot, polygon: 'POLYGON ((0.01 51.5, 0.011 51.5, 0.011 51.501, 0.01 51.501, 0.01 51.5))'))
    end

    it 'samples up to the unavailable limit, filling the rest with available tiles' do
      expect([(tiles_for_map & unavailable_tiles).size, (tiles_for_map & available_tiles).size]).to eq([2, 2])
    end

    it 'fills the rest with available tiles when there are fewer unavailable ones' do
      unavailable_tiles.first(2).each { |tile| tile.update!(latest_subscription: nil) }

      expect([tiles_for_map.size, tiles_for_map.count(&:available?)]).to eq([4, 3])
    end
  end

  describe '#hero_image_url_fallback' do
    it 'returns the hero image URL when set' do
      plot = build(:plot, hero_image_url: 'https://example.com/hero.jpg')

      expect(plot.hero_image_url_fallback).to eq 'https://example.com/hero.jpg'
    end

    it 'returns a wide placeholder with the title when blank' do
      plot = build(:plot, title: 'North Field', hero_image_url: nil)

      expect(plot.hero_image_url_fallback).to eq 'https://placehold.co/800x400?text=North%20Field'
    end
  end
end
