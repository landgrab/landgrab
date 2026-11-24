# frozen_string_literal: true

module MediaLibraryHelper
  # Everything the admin editor needs to show and insert one of a record's images
  def media_image_json(blob)
    {
      id: blob.signed_id,
      filename: blob.filename.to_s,
      alt: media_image_alt(blob),
      width: blob.metadata[:width],
      height: blob.metadata[:height],
      thumb_url: polymorphic_url(blob.variant(**MediaLibrary::VARIANTS.fetch(:thumb))),
      web_url: polymorphic_url(blob.variant(**MediaLibrary::VARIANTS.fetch(:web))),
      full_url: polymorphic_url(blob)
    }
  end

  def media_library_json(record)
    record.images.blobs.map { |blob| media_image_json(blob) }.to_json
  end

  private

  def media_image_alt(blob)
    blob.custom_metadata['alt'].presence || MediaLibrary.default_alt_text(blob.filename)
  end
end
