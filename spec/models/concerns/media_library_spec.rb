# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediaLibrary do
  describe '.default_alt_text' do
    it 'turns separators in the file name into spaces and drops the extension' do
      expect(described_class.default_alt_text('IMG_2041-woodland.edge.jpg')).to eq 'IMG 2041 woodland edge'
    end

    it 'removes brackets, which would need escaping in Markdown' do
      expect(described_class.default_alt_text('photo (1) [copy].png')).to eq 'photo 1 copy'
    end

    it 'handles a missing file name' do
      expect(described_class.default_alt_text(nil)).to eq ''
    end
  end
end
