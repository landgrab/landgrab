# frozen_string_literal: true

RSpec.describe BulletinConfirmationService do
  include ActiveJob::TestHelper

  subject(:confirm) { described_class.call(bulletin) }

  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:post) { create(:post, title: 'Spring update', published_at: 1.day.ago) }
  let(:bulletin) { create(:bulletin, posts: [post]) }

  before do
    post.post_associations.destroy_all
    [alice, bob].each do |user|
      tile = create(:tile)
      create(:subscription, tile:, subscriber: user)
      create(:post_association, post:, postable: tile)
    end
  end

  context 'when the bulletin is ready' do
    it 'confirms it' do
      expect(confirm).to be true
      expect(bulletin.reload).to be_confirmed
    end

    it 'records a delivery for each member of the audience' do
      confirm

      expect(bulletin.deliveries.map(&:user)).to contain_exactly(alice, bob)
    end

    it 'queues one email per delivery' do
      expect { confirm }.to have_enqueued_job(BulletinDeliveryJob).exactly(2).times
    end

    it 'leaves out users who have unsubscribed' do
      bob.update!(bulletin_emails: false)

      confirm

      expect(bulletin.deliveries.map(&:user)).to contain_exactly(alice)
    end
  end

  context 'when a post is not published yet' do
    before { post.update!(published_at: 1.day.from_now) }

    it 'stays a draft and explains why' do
      expect(confirm).to be false

      expect(bulletin.reload).not_to be_confirmed
      expect(bulletin.errors.full_messages).to include("Post 'Spring update' is not published yet")
    end

    it 'creates no deliveries and queues nothing' do
      expect { confirm }.not_to have_enqueued_job(BulletinDeliveryJob)
      expect(BulletinDelivery.count).to eq 0
    end
  end

  context 'when a post has no publish date' do
    before { post.update!(published_at: nil) }

    it { is_expected.to be false }
  end

  context 'when the content is too complex for an email' do
    before { post.update!(preview: "| a |\n|---|\n| 1 |") }

    it 'stays a draft and says what to simplify' do
      expect(confirm).to be false

      expect(bulletin.reload).not_to be_confirmed
      expect(bulletin.errors.full_messages).to include("Post 'Spring update': the preview contains a table.")
    end
  end

  context 'when the posts no longer share an audience' do
    it 'stays a draft with the audience rule error' do
      other = create(:post, published_at: 1.day.ago)
      create(:post_association, post: other, postable: create(:tile))
      bulletin.posts << other

      expect(confirm).to be false
      expect(bulletin.errors.full_messages.to_sentence).to include('same viewers')
    end
  end

  context 'when everyone in the audience has unsubscribed' do
    before { [alice, bob].each { |user| user.update!(bulletin_emails: false) } }

    it 'stays a draft and explains why' do
      expect(confirm).to be false

      expect(bulletin.reload).not_to be_confirmed
      expect(bulletin.errors.full_messages.to_sentence).to include('unsubscribed')
    end
  end

  context 'when already confirmed' do
    before { described_class.call(bulletin) }

    it 'does not confirm again or queue more emails' do
      expect(described_class.call(bulletin)).to be false

      expect(bulletin.errors.full_messages).to include('This bulletin has already been confirmed')
      expect(bulletin.deliveries.count).to eq 2
    end
  end
end
