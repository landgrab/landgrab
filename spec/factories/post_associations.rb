# frozen_string_literal: true

FactoryBot.define do
  factory :post_association do
    postable { create(:tile) }
    post
  end
end
