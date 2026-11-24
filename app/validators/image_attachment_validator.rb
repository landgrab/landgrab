# frozen_string_literal: true

class ImageAttachmentValidator < ActiveModel::EachValidator
  CONTENT_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_SIZE = 20.megabytes

  def validate_each(record, attribute, value)
    return unless value.attached?

    blob = value.blob
    record.errors.add(attribute, 'must be a PNG, JPEG, WebP or GIF image') unless CONTENT_TYPES.include?(blob.content_type)
    return if blob.byte_size <= MAX_SIZE

    record.errors.add(attribute, "must be smaller than #{ActiveSupport::NumberHelper.number_to_human_size(MAX_SIZE)}")
  end
end
