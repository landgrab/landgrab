# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe '#normalize_names' do
    it 'normalizes entirely lowercased first and last names' do
      simon = create(:user, first_name: 'simon', last_name: 'lópez')

      expect(simon.first_name).to eq 'Simon'
      expect(simon.last_name).to eq 'López'
    end

    it 'normalizes entirely uppercased first and last names' do
      john = create(:user, first_name: 'JOHN', last_name: 'SMITH')

      expect(john.first_name).to eq 'John'
      expect(john.last_name).to eq 'Smith'
    end

    it 'does not modify any already-capitalized first and last names' do
      gertrude = create(:user, first_name: 'gerTrüde', last_name: 'van Dyk')

      expect(gertrude.first_name).to eq 'gerTrüde'
      expect(gertrude.last_name).to eq 'van Dyk'
    end
  end

  describe '#auto_strip_attributes' do
    it 'trims whitespace on names' do
      user = build(:user, first_name: '  oscar  ', last_name: '  spacey')

      user.save!

      expect(user.first_name).to eq 'Oscar'
      expect(user.last_name).to eq 'Spacey'
    end
  end

  describe '#website_link_title' do
    it 'returns the website title when set' do
      user = build(:user, website_title: 'My Blog')
      expect(user.website_link_title).to eq 'My Blog'
    end

    it 'defaults to "Personal website" when blank' do
      user = build(:user, website_title: '')
      expect(user.website_link_title).to eq 'Personal website'
    end
  end

  describe 'website validations' do
    it 'accepts a valid https URL' do
      user = build(:user, website_url: 'https://example.com')
      expect(user).to be_valid
    end

    it 'accepts a valid http URL' do
      user = build(:user, website_url: 'http://example.com')
      expect(user).to be_valid
    end

    it 'rejects a URL without a scheme' do
      user = build(:user, website_url: 'example.com')
      expect(user).not_to be_valid
      expect(user.errors[:website_url]).to be_present
    end

    it 'accepts a blank website URL' do
      user = build(:user, website_url: '')
      expect(user).to be_valid
    end

    it 'accepts a blank website title' do
      user = build(:user, website_title: '')
      expect(user).to be_valid
    end
  end
end
