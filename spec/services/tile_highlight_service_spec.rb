# frozen_string_literal: true

RSpec.describe TileHighlightService do
  let(:viewer) { create(:user) }
  let(:profile_user) { create(:user) }
  let(:referee) { create(:user, referrer: profile_user) }
  let(:stranger) { create(:user) }
  let(:plot) { create(:plot) }

  def tile_subscribed(subscriber:, redeemer:, stripe_status: 'active', tile_plot: plot)
    create(:tile, plot: tile_plot).tap do |tile|
      create(:subscription, tile:, subscriber:, redeemer:, stripe_status:)
      tile.reload
    end
  end

  describe '#category_for' do
    context 'when viewing someone else\'s profile' do
      subject(:service) { described_class.new(viewer:, subject: profile_user) }

      it 'marks a tile the viewer redeems as mine' do
        tile = tile_subscribed(subscriber: viewer, redeemer: viewer)

        expect(service.category_for(tile)).to eq(:mine)
      end

      it 'marks a tile the profile user redeems as redeemed, whoever pays' do
        tile = tile_subscribed(subscriber: stranger, redeemer: profile_user)

        expect(service.category_for(tile)).to eq(:redeemed)
      end

      it 'marks a tile the profile user pays for but someone else redeems as gifted' do
        tile = tile_subscribed(subscriber: profile_user, redeemer: stranger)

        expect(service.category_for(tile)).to eq(:gifted)
      end

      it 'marks a tile a referee pays for as referred' do
        tile = tile_subscribed(subscriber: referee, redeemer: stranger)

        expect(service.category_for(tile)).to eq(:referred)
      end

      it 'does not mark a tile a referee only redeems' do
        tile = tile_subscribed(subscriber: stranger, redeemer: referee)

        expect(service.category_for(tile)).to be_nil
      end

      it 'prefers mine over the profile user\'s gift' do
        tile = tile_subscribed(subscriber: profile_user, redeemer: viewer)

        expect(service.category_for(tile)).to eq(:mine)
      end

      it 'prefers gifted over referred when the profile user gifts to their referee' do
        tile = tile_subscribed(subscriber: profile_user, redeemer: referee)

        expect(service.category_for(tile)).to eq(:gifted)
      end

      it 'counts free trials' do
        tile = tile_subscribed(subscriber: profile_user, redeemer: profile_user, stripe_status: 'trialing')

        expect(service.category_for(tile)).to eq(:redeemed)
      end

      it 'ignores subscriptions that are not usable' do
        tile = tile_subscribed(subscriber: profile_user, redeemer: profile_user, stripe_status: 'canceled')

        expect(service.category_for(tile)).to be_nil
      end

      it 'ignores tiles without a subscription' do
        expect(service.category_for(create(:tile, plot:))).to be_nil
      end
    end

    context 'when signed out' do
      subject(:service) { described_class.new(viewer: nil) }

      it 'marks nothing' do
        tile = tile_subscribed(subscriber: stranger, redeemer: stranger)

        expect(service.category_for(tile)).to be_nil
      end
    end
  end

  describe '#highlighted_tiles' do
    subject(:service) { described_class.new(viewer:, subject: profile_user) }

    let!(:mine) { tile_subscribed(subscriber: viewer, redeemer: viewer) }
    let!(:redeemed) { tile_subscribed(subscriber: stranger, redeemer: profile_user) }
    let!(:gifted) { tile_subscribed(subscriber: profile_user, redeemer: stranger) }
    let!(:referred) { tile_subscribed(subscriber: referee, redeemer: stranger) }
    let!(:other_plot_tile) { tile_subscribed(subscriber: profile_user, redeemer: profile_user, tile_plot: create(:plot)) }

    before do
      tile_subscribed(subscriber: stranger, redeemer: stranger)
      tile_subscribed(subscriber: stranger, redeemer: referee)
      tile_subscribed(subscriber: profile_user, redeemer: profile_user, stripe_status: 'canceled')
    end

    it 'returns every highlighted tile' do
      expect(service.highlighted_tiles).to contain_exactly(mine, redeemed, gifted, referred, other_plot_tile)
    end

    it 'limits to a plot' do
      expect(service.highlighted_tiles(plot:)).to contain_exactly(mine, redeemed, gifted, referred)
    end

    it 'returns nothing when signed out with no subject' do
      expect(described_class.new(viewer: nil).highlighted_tiles).to be_empty
    end
  end
end
