# frozen_string_literal: true

RSpec.describe ProjectMap do
  def square_polygon(offset)
    lng = offset * 0.01
    "POLYGON ((#{lng} 51.5, #{lng + 0.001} 51.5, #{lng + 0.001} 51.501, #{lng} 51.501, #{lng} 51.5))"
  end

  subject(:project_map) { described_class.new(project) }

  let(:project) { create(:project) }
  let(:meadow) { create(:plot, project:, title: 'Meadow', polygon: square_polygon(0)) }
  let(:woodland) { create(:plot, project:, title: 'Woodland', polygon: square_polygon(1)) }

  context 'when the project has no tiles' do
    before { create(:plot, project:) }

    it { is_expected.to be_empty }
  end

  context 'when the project has plots with tiles' do
    before do
      create_list(:tile, 2, plot: meadow)
      create(:subscription, tile: create(:tile, plot: meadow))
      create(:subscription, tile: create(:tile, plot: woodland))
      create(:plot, project:, title: 'Unpopulated', polygon: square_polygon(2))
      create(:tile, plot: create(:plot, title: 'Other project', polygon: square_polygon(3)))
    end

    it 'includes only the project plots that have tiles' do
      expect(project_map.plots).to contain_exactly(meadow, woodland)
    end

    it 'totals the tiles and available tiles' do
      expect([project_map.tile_count, project_map.plot_overview.total_text]).to eq([4, '2'])
    end

    it 'shows the tiles of each plot' do
      expect(project_map.tiles.map(&:plot)).to contain_exactly(meadow, meadow, meadow, woodland)
    end

    it 'labels each plot outline with its available tiles, green with some and red with none' do
      properties = JSON.parse(project_map.plot_overview.to_geojson).pluck('properties')

      expect(properties.map { |p| p.values_at('label', 'colour') })
        .to eq([['Meadow: 2 available tiles', TileMap::GREEN], ['Woodland: 0 available tiles', TileMap::RED]])
    end
  end

  context 'when a plot has more available tiles than its map sample is sure to include' do
    before do
      stub_const('Plot::MAP_TILE_LIMIT', 3)
      stub_const('Plot::MAP_UNAVAILABLE_TILE_LIMIT', 1)
      stub_const('ProjectMap::EXACT_AVAILABLE_TILE_COUNT_LIMIT', 2)
      create_list(:tile, 3, plot: meadow)
      create_list(:tile, 2, plot: woodland)
    end

    it 'labels it with a lower bound, and the others exactly' do
      labels = JSON.parse(project_map.plot_overview.to_geojson).map { |feature| feature['properties']['label'] }

      expect(labels).to eq(['Meadow: over 2 available tiles', 'Woodland: 2 available tiles'])
    end

    it 'totals the available tiles as a lower bound' do
      expect(project_map.plot_overview.total_text).to eq('over 4')
    end
  end
end
