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
end
