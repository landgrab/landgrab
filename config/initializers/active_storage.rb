# frozen_string_literal: true

case ENV['ACTIVE_STORAGE_SERVICE_PROVIDER']&.downcase&.to_sym
when nil
  # not configured; ignore
when :cloudinary
  require 'cloudinary'

  Cloudinary.config_from_url(ENV.fetch('CLOUDINARY_URL'))
when :s3
  # no additional setup needed; see config/storage/production.yml
else
  raise "ActiveStorage service provider '#{ENV.fetch('ACTIVE_STORAGE_SERVICE_PROVIDER', nil)}' is not handled"
end
