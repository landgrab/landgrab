# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tile do
  let(:tile_params) { { w3w: 'aaa.bbb.ccc', southwest: 1, northeast: 1 } }
  let(:tile) { described_class.new(tile_params) }

  it 'is valid by default' do
    expect(tile).to be_valid
  end

  describe '#validates w3w' do
    it 'rejects two-word what3words' do
      tile.w3w = 'two.words'

      tile.validate

      expect(tile.errors[:w3w]).to include('format should be a.b.c')
    end

    it 'rejects extra what3words text' do
      tile.w3w = 'something//one.two.three|garbage'

      tile.validate

      expect(tile.errors[:w3w]).to include('format should be a.b.c')
    end
  end

  describe '#viewable_by?' do
    subject(:viewable) { tile.viewable_by?(user) }

    let(:user) { create(:user) }
    let(:tile) { create(:tile) }
    let(:subscription) { create(:subscription, subscriber: user, tile:) }

    before { subscription }

    it 'returns true if tile subscribed' do
      expect(viewable).to be true
    end

    it 'returns false if tile unsubscribed' do
      subscription.destroy
      tile.reload

      expect(viewable).to be false
    end

    it 'returns false if tile subscribed by another user' do
      subscription.update!(subscriber: create(:user))
      tile.reload

      expect(viewable).to be false
    end
  end
end
