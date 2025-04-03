# frozen_string_literal: true

class LandgrabService
  SOURCE_CODE_REPO_URL = 'https://github.com/landgrab/landgrab'

  def self.attachments_enabled?
    return true if Rails.env.local?

    ENV.key?('ACTIVE_STORAGE_S3_BUCKET_NAME')
  end
end
