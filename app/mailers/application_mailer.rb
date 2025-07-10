# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # NOTE: If changing this, also update `config.mailer_sender` in `config/initializers/devise.rb`
  default from: "\"#{ENV.fetch('SITE_TITLE', 'Landgrab')} Support\" <#{LandgrabService.email_from_address}>".freeze

  layout 'mailer'
end
