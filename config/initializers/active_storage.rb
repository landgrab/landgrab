# frozen_string_literal: true

case ENV['ACTIVE_STORAGE_SERVICE_PROVIDER']&.downcase&.to_sym
when nil
  # not configured; ignore
when :cloudinary
    require 'cloudinary'

    Cloudinary.config_from_url(ENV.fetch('CLOUDINARY_URL'))
else
    raise "ActiveStorage service provider '#{ENV['ACTIVE_STORAGE_SERVICE_PROVIDER']}' is not handled"
end
