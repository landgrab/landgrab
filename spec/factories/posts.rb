# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    title { 'My Post Title' }
    body { 'My Post Body' }

    author factory: %i[user]

    # Associated with a tile that has a subscriber, so the post has one viewer
    trait :viewed_by_subscriber do
      after(:create) do |post|
        tile = create(:tile)
        create(:subscription, tile:, subscriber: create(:user))
        create(:post_association, post:, postable: tile)
      end
    end
  end
end
