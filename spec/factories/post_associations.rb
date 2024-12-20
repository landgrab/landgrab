# frozen_string_literal: true

FactoryBot.define do
  factory :post_association do
    postable { association :tile }
    post
  end
end
