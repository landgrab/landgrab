# frozen_string_literal: true

class LandgrabService
  SOURCE_CODE_REPO_URL = 'https://github.com/landgrab/landgrab'

  def self.attachments_enabled?
    active_storage_service_provider.present?
  end

  def self.active_storage_service_provider
    ENV.fetch('ACTIVE_STORAGE_SERVICE_PROVIDER', nil)&.downcase&.to_sym
  end
end
