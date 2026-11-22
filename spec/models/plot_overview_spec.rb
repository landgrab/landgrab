# frozen_string_literal: true

RSpec.describe PlotOverview do
  def square_polygon(offset)
    lng = offset * 0.01
    "POLYGON ((#{lng} 51.5, #{lng + 0.001} 51.5, #{lng + 0.001} 51.501, #{lng} 51.501, #{lng} 51.5))"
  end

  subject(:overview) { described_class.new(plots: [woodland, meadow], tiles:, tile_name: 'team tile') }

  let(:meadow) { create(:plot, title: 'Meadow', polygon: square_polygon(0)) }
  let(:woodland) { create(:plot, title: 'Woodland', polygon: square_polygon(1)) }
  let(:tiles) { [create(:tile, plot: woodland), create(:tile, plot: woodland), create(:tile, plot: meadow)] }

  describe '#label' do
    it 'names the plot and counts its tiles' do
      expect([overview.label(woodland), overview.label(meadow)])
        .to eq(['Woodland: 2 team tiles', 'Meadow: 1 team tile'])
    end

    it 'shows a count over the count limit as a lower bound' do
      overview = described_class.new(plots: [woodland, meadow], tiles:, count_limit: 1)

      expect([overview.label(woodland), overview.label(meadow)]).to eq(['Woodland: over 1 tiles', 'Meadow: 1 tile'])
    end
  end

  describe '#total_text' do
    it 'totals the tiles across every plot' do
      expect(overview.total_text).to eq('3')
    end

    it 'gives a lower bound when any plot is over the count limit, counting it at the limit' do
      expect(described_class.new(plots: [woodland, meadow], tiles:, count_limit: 1).total_text).to eq('over 2')
    end
  end

  describe '#to_geojson' do
    let(:features) { JSON.parse(overview.to_geojson) }

    it 'outlines each plot by title, in orange, with its id, label and tile count' do
      expect(features.pluck('properties')).to eq([
                                                   { 'id' => meadow.id, 'title' => 'Meadow', 'label' => 'Meadow: 1 team tile', 'tile_count' => 1, 'colour' => TileMap::ORANGE },
                                                   { 'id' => woodland.id, 'title' => 'Woodland', 'label' => 'Woodland: 2 team tiles', 'tile_count' => 2, 'colour' => TileMap::ORANGE }
                                                 ])
    end

    it 'colours each outline by its tile count when given a colour' do
      overview = described_class.new(plots: [woodland, meadow], tiles: tiles.first(2), colour: ->(count) { count.positive? ? 'green' : 'red' })

      expect(JSON.parse(overview.to_geojson).map { |feature| feature['properties']['colour'] }).to eq(%w[red green])
    end

    it 'uses each plot polygon as the outline' do
      expect(features.first).to include('type' => 'Feature')
      expect(features.first['geometry']).to eq(RGeo::GeoJSON.encode(meadow.polygon).as_json)
    end
  end
end
