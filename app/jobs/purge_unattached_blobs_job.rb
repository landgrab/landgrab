# frozen_string_literal: true

# Removes uploads that never made it onto a record, such as media library images from a form that
# was abandoned, or images an admin has since removed from a record.
class PurgeUnattachedBlobsJob < ApplicationJob
  queue_as :default

  GRACE_PERIOD = 2.days

  def perform
    ActiveStorage::Blob.unattached.where(created_at: ..GRACE_PERIOD.ago).find_each(&:purge_later)
  end
end
