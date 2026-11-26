# frozen_string_literal: true

RSpec.describe Bulletin do
  subject(:bulletin) { build(:bulletin) }

  def post_viewed_by(*users, title: 'A post')
    post = create(:post, title:)
    users.each do |user|
      tile = create(:tile)
      create(:subscription, tile:, subscriber: user)
      create(:post_association, post:, postable: tile)
    end
    post
  end

  it { is_expected.to be_valid }

  it 'needs a subject' do
    bulletin.subject = ' '

    expect(bulletin).not_to be_valid
    expect(bulletin.errors[:subject]).to be_present
  end

  it 'needs at least one post' do
    bulletin.posts = []

    expect(bulletin).not_to be_valid
    expect(bulletin.errors[:posts]).to be_present
  end

  it 'does not need intro text' do
    bulletin.intro = nil

    expect(bulletin).to be_valid
  end

  it 'cannot include the same post twice' do
    bulletin.save!

    duplicate = bulletin.bulletin_posts.build(post: bulletin.posts.first)

    expect(duplicate).not_to be_valid
  end

  describe 'audience rule' do
    let(:alice) { create(:user) }
    let(:bob) { create(:user) }

    it 'accepts several posts with exactly the same viewers' do
      bulletin.posts = [post_viewed_by(alice, bob), post_viewed_by(alice, bob)]

      expect(bulletin).to be_valid
    end

    it 'accepts posts given the same associations' do
      project = create(:project)
      create(:subscription, tile: create(:tile, plot: create(:plot, project:)), subscriber: alice)
      bulletin.posts = create_list(:post, 2).each { |post| create(:post_association, post:, postable: project) }

      expect(bulletin).to be_valid
    end

    context 'when one user can view one post but not another' do
      before { bulletin.posts = [post_viewed_by(alice, bob, title: 'Big news'), post_viewed_by(alice, title: 'Small news')] }

      it 'is rejected' do
        expect(bulletin).not_to be_valid
      end

      it 'reports each post\'s viewer count and how many users differ' do
        bulletin.validate

        message = bulletin.errors.full_messages.to_sentence
        expect(message).to include("'Big news' (2 viewers)", "'Small news' (1 viewer)", '1 user can view some of them but not all')
      end

      it 'suggests giving every post the same associations' do
        bulletin.validate

        expect(bulletin.errors.full_messages.to_sentence).to include('give every post the same associations')
      end

      it 'does not name or email any user' do
        bulletin.validate

        message = bulletin.errors.full_messages.to_sentence
        expect(message).not_to include(alice.email, bob.email, alice.first_name)
      end
    end

    it 'rejects posts with no viewers at all' do
      bulletin.posts = [create(:post)]

      expect(bulletin).not_to be_valid
      expect(bulletin.errors.full_messages.to_sentence).to include('no viewers')
    end

    it 'rejects posts whose viewers differ even when they overlap in size' do
      bulletin.posts = [post_viewed_by(alice), post_viewed_by(bob)]

      expect(bulletin).not_to be_valid
    end
  end

  describe '#content_problems' do
    it 'is empty for simple content' do
      bulletin.intro = 'Hello **there**'
      bulletin.posts.first.update!(preview: 'A *simple* preview')

      expect(bulletin.content_problems).to be_empty
    end

    it 'names the post and the unsupported element in a post preview' do
      post = bulletin.posts.first
      post.update!(title: 'Spring update', preview: "| a |\n|---|\n| 1 |")

      expect(bulletin.content_problems).to eq ["Post 'Spring update': the preview contains a table."]
    end

    it 'reports unsupported elements in the intro' do
      bulletin.intro = '## Big news'

      expect(bulletin.content_problems).to eq ['The intro contains a heading.']
    end
  end

  describe '#audience' do
    it 'is the users who can view the posts' do
      alice = create(:user)
      bulletin.posts = [post_viewed_by(alice)]

      expect(bulletin.audience).to contain_exactly(alice)
    end

    it 'is empty without posts' do
      bulletin.posts = []

      expect(bulletin.audience).to be_empty
    end
  end
end
