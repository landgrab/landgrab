# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project do
  let(:project) { build(:project) }

  it 'is valid by default' do
    expect(project).to be_valid
  end

  describe '#viewable_by?' do
    subject(:viewable) { project.viewable_by?(user) }

    let(:user) { create(:user) }
    let(:plot) { create(:plot, project:) }
    let(:tile) { create(:tile, plot:) }
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

    it 'returns false if tile assigned to different plot' do
      tile.plot.destroy # avoid new plot conflicting with old plot's polygon
      tile.update!(plot: create(:plot))
      tile.reload

      expect(viewable).to be false
    end

    it 'returns false if plot assigned to different project' do
      plot.update!(project: create(:project))

      expect(viewable).to be false
    end
  end

  describe '#hero_image_for_display' do
    it 'returns the hero image URL when set' do
      project = build(:project, hero_image_url: 'https://example.com/hero.jpg')

      expect(project.hero_image_for_display).to eq 'https://example.com/hero.jpg'
    end

    it 'returns a wide placeholder with the title when blank' do
      project = build(:project, title: 'Big Wood', hero_image_url: nil)

      expect(project.hero_image_for_display).to eq 'https://placehold.co/800x400?text=Big%20Wood'
    end
  end

  describe '#logo_for_display' do
    it 'returns the logo URL when set' do
      project = build(:project, logo_url: 'https://example.com/logo.png')

      expect(project.logo_for_display).to eq 'https://example.com/logo.png'
    end

    it 'returns a square logo placeholder when blank' do
      project = build(:project, logo_url: '')

      expect(project.logo_for_display).to eq 'https://placehold.co/400x400?text=Logo'
    end
  end
end
