# frozen_string_literal: true

namespace :images do
  desc 'Store images linked to by URL in Active Storage, clearing their URLs (DRY_RUN=1 lists them without storing)'
  task store_external_urls: :environment do
    unless LandgrabService.attachments_enabled?
      puts 'Attachments are not enabled, so there is nowhere to store images. Nothing done.'
      next
    end

    dry_run = ENV['DRY_RUN'].present?
    $stdout.sync = true
    result = ExternalImageStorageService.store_all(dry_run:) { |label, url| puts "Storing #{label}: #{url}" }

    if dry_run
      puts "Dry run: would store #{result.stored.size} image(s), skipping #{result.skipped} already stored."
      result.stored.each { |label| puts "  #{label}" }
    else
      puts "Stored #{result.stored.size} image(s), skipped #{result.skipped} already stored, " \
           "#{result.failures.size} failed."
      result.failures.each { |failure| puts "  #{failure.label}: #{failure.error}" }
    end
  end
end
