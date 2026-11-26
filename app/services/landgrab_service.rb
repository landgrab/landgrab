# frozen_string_literal: true

class LandgrabService
  SOURCE_CODE_REPO_URL = 'https://github.com/landgrab/landgrab'

  def self.attachments_enabled?
    active_storage_service_provider.present?
  end

  def self.active_storage_service_provider
    ENV.fetch('ACTIVE_STORAGE_SERVICE_PROVIDER', nil)&.downcase&.to_sym
  end

  def self.email_from_address
    ENV.fetch('EMAIL_FROM_ADDRESS', 'landgrab@example.com')
  end

  # Who the sender is, shown in the footer of bulletin emails (UK PECR requires the sender's identity)
  def self.email_organisation_name
    ENV.fetch('EMAIL_ORGANISATION_NAME') { ENV.fetch('SITE_TITLE', 'Landgrab') }
  end

  def self.email_postal_address
    ENV.fetch('EMAIL_POSTAL_ADDRESS', '1 Example Street, London, EX1 1AA')
  end
end
