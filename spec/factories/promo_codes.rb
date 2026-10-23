# frozen_string_literal: true

FactoryBot.define do
  factory :promo_code do
    code { 'BONUS1000' }
    stripe_id { 'promo_abc123' }

    trait :free_trial do
      stripe_id { nil }
      free_trial_days { 14 }
    end
  end
end
