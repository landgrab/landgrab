# frozen_string_literal: true

FactoryBot.define do
  factory :bulletin_delivery do
    bulletin
    user
  end
end
