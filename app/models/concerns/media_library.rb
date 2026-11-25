# frozen_string_literal: true

# A library of images that admins can upload to a record (for example a post) and insert into
# any of the record's Markdown text fields.
#
# Images are Active Storage attachments. They are uploaded ahead of saving the record, so a
# new image is an unattached blob until the record is saved with its signed id.
module MediaLibrary
  extend ActiveSupport::Concern

  VARIANTS = {
    thumb: { resize_to_fill: [100, 100] },
    web: { resize_to_limit: [822, 822] }
  }.freeze

  class << self
    # A starting point for alt text, taken from the file name:
    # "IMG_2041-woodland-edge.jpg" becomes "IMG 2041 woodland edge".
    # Brackets are removed because they would need escaping inside Markdown image syntax.
    def default_alt_text(filename)
      File.basename(filename.to_s, '.*').gsub(/[\[\]()_.-]+/, ' ').squish
    end
  end

  class_methods do
    def media_library
      return unless LandgrabService.attachments_enabled?

      has_many_attached :images, dependent: :detach do |attachable|
        VARIANTS.each { |name, options| attachable.variant(name, **options) }
      end
    end
  end
end
