# frozen_string_literal: true

# An optional image which admins can either upload or give the URL of.
#
# When attachments are enabled, a newly given URL is downloaded into storage and the URL
# cleared, so the URL column only ever holds an external image that hasn't been stored yet
# (from before uploads existed, or from an environment without uploads configured).
# Stored images take priority over that URL, which takes priority over a placeholder.
module StoredImage
  extend ActiveSupport::Concern

  HERO_IMAGE_VARIANTS = {
    thumb: { resize_to_fill: [600, 300] },
    web: { resize_to_limit: [1600, 800] }
  }.freeze

  LOGO_VARIANTS = {
    thumb: { resize_to_limit: [400, 400] }
  }.freeze

  class_methods do
    def stored_image(name, url_attribute:, variants:, placeholder:)
      has_one_attached name do |attachable|
        variants.each { |variant, options| attachable.variant(variant, **options) }
      end

      attribute :"remove_#{name}", :boolean, default: false

      before_validation { remove_image(name, url_attribute) }
      validates url_attribute, url: true, allow_blank: true
      validate { store_image_from_url(name, url_attribute) }
      validates name, image_attachment: true
      before_save { clear_url_of_stored_image(name, url_attribute) }

      define_method(:"#{name}_for_display") do |variant = nil|
        image_for_display(name, url_attribute, variant) || instance_exec(&placeholder)
      end

      define_method(:"#{name}_placeholder?") do
        image_for_display(name, url_attribute).nil?
      end
    end
  end

  private

  def image_stored?(name)
    image = public_send(name)
    LandgrabService.attachments_enabled? && image.attached? && image.blob.persisted?
  end

  def image_for_display(name, url_attribute, variant = nil)
    if image_stored?(name)
      image = public_send(name)
      variant ? image.variant(variant) : image
    else
      self[url_attribute].presence
    end
  end

  def new_image_url?(url_attribute)
    self[url_attribute].present? && will_save_change_to_attribute?(url_attribute)
  end

  def image_uploaded?(name)
    attachment_changes[name.to_s].is_a?(ActiveStorage::Attached::Changes::CreateOne)
  end

  def remove_image(name, url_attribute)
    return unless public_send(:"remove_#{name}")
    return if image_uploaded?(name) || new_image_url?(url_attribute)

    public_send(:"#{name}=", nil) if LandgrabService.attachments_enabled?
    self[url_attribute] = nil
  end

  def store_image_from_url(name, url_attribute)
    return unless LandgrabService.attachments_enabled? && new_image_url?(url_attribute)
    return if errors.include?(url_attribute)

    url = self[url_attribute]
    return if downloaded_image_urls[name] == url

    if image_uploaded?(name)
      errors.add(url_attribute, 'cannot be given as well as an uploaded image')
      return
    end

    download = ImageDownloadService.download(url, max_bytes: ImageAttachmentValidator::MAX_SIZE)
    public_send(:"#{name}=", { io: download.io, filename: download.filename, content_type: download.content_type })
    downloaded_image_urls[name] = url
  rescue ImageDownloadService::Error => e
    errors.add(url_attribute, e.message)
  end

  def clear_url_of_stored_image(name, url_attribute)
    self[url_attribute] = nil if image_uploaded?(name)
  end

  def downloaded_image_urls
    @downloaded_image_urls ||= {}
  end
end
