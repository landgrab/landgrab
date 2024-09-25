# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    title { 'Test Project' }

    logo_url { 'https://example.com/logo.png' }
  end
end
