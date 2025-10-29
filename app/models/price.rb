# frozen_string_literal: true

class Price < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :amount_display, presence: true
  validates :stripe_id, format: { with: /\Aprice_[0-9a-zA-Z]+\z/, message: 'must start with price_' }

  auto_strip_attributes :title, :amount_display, :stripe_id, squish: true
end
