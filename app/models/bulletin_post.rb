# frozen_string_literal: true

class BulletinPost < ApplicationRecord
  belongs_to :bulletin
  belongs_to :post

  validates :post_id, uniqueness: { scope: :bulletin_id, message: 'is already in this bulletin' }
end
