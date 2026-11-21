# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team do
  describe '#logo_url_fallback' do
    it 'returns the logo URL when set' do
      team = build(:team, logo_url: 'https://example.com/team-logo.png')

      expect(team.logo_url_fallback).to eq 'https://example.com/team-logo.png'
    end

    it 'returns a square logo placeholder when blank' do
      team = build(:team, logo_url: '')

      expect(team.logo_url_fallback).to eq 'https://placehold.co/400x400?text=Logo'
    end
  end
end
