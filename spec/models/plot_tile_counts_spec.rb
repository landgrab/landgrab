# frozen_string_literal: true

RSpec.describe PlotTileCounts do
  subject(:counts) { described_class.new(Plot.where(id: [meadow, woodland, fallow])) }

  def square_polygon(offset)
    lng = offset * 0.01
    "POLYGON ((#{lng} 51.5, #{lng + 0.001} 51.5, #{lng + 0.001} 51.501, #{lng} 51.501, #{lng} 51.5))"
  end

  let(:meadow) { create(:plot, polygon: square_polygon(0)) }
  let(:woodland) { create(:plot, polygon: square_polygon(1)) }
  let(:fallow) { create(:plot, polygon: square_polygon(2)) }

  before do
    create_list(:tile, 2, plot: meadow)
    create(:subscription, tile: create(:tile, plot: meadow))
    create(:subscription, tile: create(:tile, plot: woodland))
    create(:tile, plot: create(:plot, polygon: square_polygon(3)))
  end

  it 'counts the tiles in each plot' do
    expect([meadow, woodland, fallow].map { |plot| counts.total(plot) }).to eq([3, 1, 0])
  end

  it 'counts the available tiles in each plot' do
    expect([meadow, woodland, fallow].map { |plot| counts.available(plot) }).to eq([2, 0, 0])
  end
end
