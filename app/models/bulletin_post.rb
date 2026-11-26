# frozen_string_literal: true

class BulletinPost < ApplicationRecord
  belongs_to :bulletin
  belongs_to :post

  validates :post_id, uniqueness: { scope: :bulletin_id, message: 'is already in this bulletin' }

  validate :bulletin_not_confirmed, on: :create
  before_destroy :bulletin_not_confirmed_for_destroy

  private

  def bulletin_not_confirmed
    errors.add(:base, 'A confirmed bulletin cannot be changed') if bulletin&.confirmed?
  end

  def bulletin_not_confirmed_for_destroy
    throw :abort if bulletin&.confirmed? && !destroyed_by_association
  end
end
