# frozen_string_literal: true

RSpec.describe BulletinMailer do
  let(:user) { create(:user, first_name: 'Freya') }
  let(:post) { create(:post, title: 'Spring planting', preview: 'The **first** trees went in. [Map](/projects)') }
  let(:bulletin) { build(:bulletin, subject: 'News from the land', intro: 'Hello *there*', posts: [post]) }
  let(:token) { user.generate_token_for(:bulletin_unsubscribe) }

  def deliver
    described_class.with(bulletin:, user:).bulletin.deliver_now
    ActionMailer::Base.deliveries.last
  end

  before { ActionMailer::Base.deliveries.clear }

  describe 'headers' do
    subject(:mail) { deliver }

    it { is_expected.to have_attributes(to: [user.email], subject: 'News from the land') }

    it 'offers one-click unsubscribe to mail clients' do
      expect(mail['List-Unsubscribe'].to_s).to eq "<#{bulletin_one_click_unsubscribe_url(token)}>"
      expect(mail['List-Unsubscribe-Post'].to_s).to eq 'List-Unsubscribe=One-Click'
    end
  end

  describe 'html body' do
    subject(:html) { deliver.html_part.body.decoded }

    it 'greets the user and shows the intro' do
      expect(html).to include('Hi Freya,', '<em>there</em>')
    end

    it 'shows each post with its title and preview, linking to the post' do
      expect(html).to include('Spring planting', '<strong>first</strong>', %(href="#{post_url(post)}"), 'Read more')
    end

    it 'makes relative links in previews absolute' do
      expect(html).to include('href="http://example.com/projects"')
    end

    it 'links to the user\'s tiles' do
      expect(html).to include(%(href="#{my_tile_url}"), 'View your tile(s)')
    end

    it 'has a footer with a working unsubscribe link, the organisation name and the postal address' do
      expect(html).to include(%(href="#{bulletin_unsubscribe_url(token)}"), LandgrabService.email_organisation_name, LandgrabService.email_postal_address)
    end

    it 'has its styles inlined' do
      expect(html).to match(/<p style="[^"]*margin/)
    end

    it 'leaves out the intro when there is none' do
      bulletin.intro = nil

      expect(html).not_to include('Hello')
    end
  end

  describe 'text body' do
    subject(:text) { deliver.text_part.body.decoded }

    it 'is generated from the html' do
      expect(text).to include('Hi Freya', 'Spring planting', 'first trees went in', bulletin_unsubscribe_url(token))
    end
  end

  it 'refuses content that is too complex for an email' do
    post.update!(preview: "| a | b |\n|---|---|\n| 1 | 2 |")

    expect { deliver }.to raise_error(ArgumentError, /contains a table/)
  end

  it 'does not deliver unsubscribe tokens that belong to another user' do
    other_token = create(:user).generate_token_for(:bulletin_unsubscribe)

    expect(deliver.html_part.body.decoded).not_to include(other_token)
  end
end
