# frozen_string_literal: true

RSpec.describe TileService do
  describe '#distance_between_tile_midpoints_human' do
    let(:tile_above) do
      build(:tile,
            w3w: 'encodes.twist.youths',
            southwest: 'POINT(-3.198844 52.349423)',
            northeast: 'POINT(-3.198799 52.349450)')
    end

    let(:tile_below) do
      build(:tile,
            w3w: 'pickle.tablet.blueberry',
            southwest: 'POINT(-3.198844 52.349396)',
            northeast: 'POINT(-3.198799 52.349423)')
    end

    let(:eiffel_tower) do
      build(:tile,
            w3w: 'prices.slippery.traps',
            southwest: 'POINT(2.294453 48.858344)',
            northeast: 'POINT( 2.294494 48.858371)')
    end

    let(:notre_dame_cathedral) do
      build(:tile,
            w3w: 'rashers.twice.balanced',
            southwest: 'POINT(2.349885 48.852954)',
            northeast: 'POINT(2.349926 48.852981)')
    end

    let(:statue_of_liberty) do
      build(:tile,
            w3w: 'planet.inches.most',
            southwest: 'POINT(-74.044511 40.689225)',
            northeast: 'POINT(-74.044475 40.689252)')
    end

    it 'calculates the distance between a tile and itself as zero!' do
      result = described_class.distance_between_tile_midpoints_human(tile_above, tile_above)

      expect(result).to eq('0 m')
    end

    it 'calculates the distance between two adjacent tiles' do
      result = described_class.distance_between_tile_midpoints_human(tile_above, tile_below)

      # adjacent W3W tiles are ~ 3m apart!
      expect(result).to eq('3 m')
    end

    it 'calculates the distance between two tiles with medium distances' do
      result = described_class.distance_between_tile_midpoints_human(eiffel_tower, notre_dame_cathedral)

      expect(result).to eq('4.1 km')
    end

    it 'calculates the distance between two tiles with large distances' do
      result = described_class.distance_between_tile_midpoints_human(eiffel_tower, statue_of_liberty)

      expect(result).to eq('5844 km')
    end
  end
end
