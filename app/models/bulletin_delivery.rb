# frozen_string_literal: true

# One bulletin's email to one user. The user is kept as a nullable reference so the record of what
# was sent survives the user's account being deleted; `email` is the address it actually went to.
class BulletinDelivery < ApplicationRecord
  belongs_to :bulletin
  belongs_to :user, optional: true

  scope :sent, -> { where.not(sent_at: nil) }
  scope :failed, -> { where.not(failed_at: nil) }
  scope :pending, -> { where(sent_at: nil, failed_at: nil) }

  def sent?
    sent_at.present?
  end

  def failed?
    failed_at.present?
  end

  def pending?
    !sent? && !failed?
  end
end
