# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlaceholderImageService do
  describe '.url' do
    it 'builds a placehold.co URL with the given dimensions and text' do
      expect(described_class.url(width: 400, height: 300, text: 'Logo'))
        .to eq 'https://placehold.co/400x300?text=Logo'
    end

    it 'encodes spaces and reserved characters in the text' do
      expect(described_class.url(width: 800, height: 400, text: 'Bees & Trees #1'))
        .to eq 'https://placehold.co/800x400?text=Bees%20%26%20Trees%20%231'
    end
  end
end
