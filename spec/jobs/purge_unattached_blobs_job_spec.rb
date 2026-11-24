# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeUnattachedBlobsJob do
  include ActiveJob::TestHelper

  def create_blob(created_at:)
    ActiveStorage::Blob.create_and_upload!(
      io: file_fixture('images/pixel.png').open, filename: 'pixel.png', content_type: 'image/png'
    ).tap { |blob| blob.update!(created_at:) }
  end

  it 'purges uploads that were never attached once the grace period has passed' do
    old_blob = create_blob(created_at: 3.days.ago)

    perform_enqueued_jobs { described_class.perform_now }

    expect(ActiveStorage::Blob.exists?(old_blob.id)).to be false
  end

  it 'keeps recent uploads, which may still be waiting for their form to be saved' do
    recent_blob = create_blob(created_at: 1.hour.ago)

    perform_enqueued_jobs { described_class.perform_now }

    expect(ActiveStorage::Blob.exists?(recent_blob.id)).to be true
  end

  it 'keeps uploads that are attached to a record' do
    attached_blob = create_blob(created_at: 3.days.ago)
    ActiveStorage::Attachment.create!(name: 'images', record: create(:post), blob: attached_blob)

    perform_enqueued_jobs { described_class.perform_now }

    expect(ActiveStorage::Blob.exists?(attached_blob.id)).to be true
  end
end
