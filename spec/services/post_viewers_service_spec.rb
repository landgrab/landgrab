# frozen_string_literal: true

RSpec.describe PostViewersService do
  subject(:viewers) { described_class.call(post) }

  let(:post) { create(:post) }
  let(:project) { create(:project) }
  let(:plot) { create(:plot, project:) }
  let(:tile) { create(:tile, plot:) }
  let(:subscriber) { create(:user) }
  let(:redeemer) { create(:user) }

  def associate(postable)
    create(:post_association, post:, postable:)
  end

  context 'when the post has no associations' do
    it { is_expected.to be_empty }
  end

  context 'when associated with a tile' do
    before do
      create(:subscription, tile:, subscriber:, redeemer:)
      associate(tile)
    end

    it { is_expected.to contain_exactly(subscriber, redeemer) }

    it 'excludes users without a subscription on the tile' do
      other_tile = create(:tile, plot:)
      create(:subscription, tile: other_tile, subscriber: create(:user))

      expect(viewers).to contain_exactly(subscriber, redeemer)
    end

    it 'only counts the latest subscription on the tile' do
      newer_subscriber = create(:user)
      create(:subscription, tile:, subscriber: newer_subscriber)

      expect(viewers).to contain_exactly(newer_subscriber)
    end
  end

  context 'when associated with a plot' do
    before do
      create(:subscription, tile:, subscriber:, redeemer:)
      associate(plot)
    end

    it 'includes the subscriber but not the redeemer of its tiles' do
      expect(viewers).to contain_exactly(subscriber)
    end
  end

  context 'when associated with a project' do
    before do
      create(:subscription, tile:, subscriber:, redeemer:)
      associate(project)
    end

    it 'includes the subscriber but not the redeemer of tiles in its plots' do
      expect(viewers).to contain_exactly(subscriber)
    end

    it 'excludes subscribers in other projects' do
      far_polygon = 'POLYGON ((-1.02018 52.51576, -1.02002 52.51591, -1.01981 52.51558, -1.02018 52.51576))'
      other_tile = create(:tile, plot: create(:plot, project: create(:project), polygon: far_polygon))
      create(:subscription, tile: other_tile, subscriber: create(:user))

      expect(viewers).to contain_exactly(subscriber)
    end
  end

  context 'when associated with a team' do
    let(:team) { create(:team) }
    let(:member) { create(:user, team:) }

    before do
      member
      create(:user)
      associate(team)
    end

    it { is_expected.to contain_exactly(member) }
  end

  context 'when associated with several postables' do
    let(:team) { create(:team) }
    let(:member) { create(:user, team:) }

    before do
      create(:subscription, tile:, subscriber:)
      associate(tile)
      associate(team)
      member
    end

    it 'combines their viewers without duplicates' do
      create(:subscription, tile: create(:tile), subscriber: member)
      associate(Tile.find_by(latest_subscription: Subscription.find_by(subscriber: member)))

      expect(viewers.ids).to contain_exactly(subscriber.id, member.id)
    end
  end

  describe 'agreement with Post#viewable_by?' do
    before do
      team = create(:team)
      create(:user, team:)
      create(:user)
      create(:subscription, tile: create(:tile, plot:), subscriber:, redeemer:)
      create(:subscription, tile: create(:tile), subscriber: create(:user), stripe_status: 'canceled')
      [plot, project, team, Tile.last].each { |postable| associate(postable) }
    end

    it 'finds exactly the users that viewable_by? accepts' do
      expected = User.all.select { |user| post.viewable_by?(user) }

      expect(viewers).to match_array(expected)
    end
  end
end
