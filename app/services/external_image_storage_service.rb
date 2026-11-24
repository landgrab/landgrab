# frozen_string_literal: true

# Stores the external images that records link to by URL (from before uploads existed),
# so that every image is held in Active Storage and the URL columns can be dropped.
#
# Each image is stored by re-saving its record with the URL marked as changed, which makes
# StoredImage download it, attach it and clear the URL. An image that can't be stored keeps
# its URL and is reported as a failure.
class ExternalImageStorageService
  class AttachmentsDisabledError < StandardError; end

  Failure = Data.define(:label, :error)

  # What was stored (or, in a dry run, would be stored), skipped and failed
  class Result
    attr_reader :stored, :failures
    attr_accessor :skipped

    def initialize
      @stored = []
      @skipped = 0
      @failures = []
    end
  end

  class << self
    # Yields each image's label and URL just before attempting to store it (not on a dry run)
    def store_all(dry_run: false, &before_attempt)
      raise AttachmentsDisabledError, 'attachments are not enabled' unless LandgrabService.attachments_enabled?

      Result.new.tap do |result|
        each_external_image do |record, name, url_attribute|
          store(record, name, url_attribute, result, dry_run:, before_attempt:)
        end
      end
    end

    private

    # Each model's stored images, mapped to the attributes holding their URLs
    def url_attributes
      {
        Project => { hero_image: :hero_image_url, logo: :logo_url },
        Plot => { hero_image: :hero_image_url },
        Team => { logo: :logo_url }
      }
    end

    def each_external_image
      url_attributes.each do |model, images|
        images.each do |name, url_attribute|
          model.reorder(nil).where.not(url_attribute => [nil, '']).find_each do |record|
            yield record, name, url_attribute
          end
        end
      end
    end

    def store(record, name, url_attribute, result, dry_run:, before_attempt:)
      label = "#{record.class.name} #{record.id} (#{record.to_param}) #{name}"

      if record.public_send(name).attached?
        result.skipped += 1
      elsif dry_run
        result.stored << label
      else
        before_attempt&.call(label, record[url_attribute])
        save_with_image(record, url_attribute, label, result)
      end
    end

    def save_with_image(record, url_attribute, label, result)
      record.public_send(:"#{url_attribute}_will_change!")

      if record.save
        result.stored << label
      else
        result.failures << Failure.new(label:, error: record.errors.full_messages.to_sentence)
      end
    rescue StandardError => e
      result.failures << Failure.new(label:, error: "#{e.class}: #{e.message}")
    end
  end
end
