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
  end

  describe '#to_geojson' do
    let(:features) { JSON.parse(overview.to_geojson) }

    it 'outlines each plot by title, in orange, with its id, label and tile count' do
      expect(features.pluck('properties')).to eq([
                                                   { 'id' => meadow.id, 'title' => 'Meadow', 'label' => 'Meadow: 1 team tile', 'tile_count' => 1, 'colour' => TileMap::ORANGE },
                                                   { 'id' => woodland.id, 'title' => 'Woodland', 'label' => 'Woodland: 2 team tiles', 'tile_count' => 2, 'colour' => TileMap::ORANGE }
                                                 ])
    end

    it 'uses each plot polygon as the outline' do
      expect(features.first).to include('type' => 'Feature')
      expect(features.first['geometry']).to eq(RGeo::GeoJSON.encode(meadow.polygon).as_json)
    end
  end
end
