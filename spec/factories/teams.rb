# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    sequence(:title, 'a') { |n| "Example Team #{n}" }
    sequence(:slug, 'a') { |n| "slug-#{n}" }
  end
end
