# frozen_string_literal: true

class PromoCode < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :stripe_id, format: { with: /\Apromo_[0-9a-zA-Z]+\z/ }, uniqueness: true
end
