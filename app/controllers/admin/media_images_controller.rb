# frozen_string_literal: true

module Admin
  # Immediate uploads for the admin media library, ahead of the owning record being saved.
  class MediaImagesController < ApplicationController
    before_action :check_admin
    before_action :check_attachments_enabled

    rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :render_not_found

    def create
      source = image_source
      return render_error('is required') unless source
      return render_error(source.error) if source.error

      blob = store(source)
      return render_error(invalid_type_message, blob) unless ImageAttachmentValidator::CONTENT_TYPES.include?(blob.content_type)

      render json: helpers.media_image_json(blob), status: :created
    end

    def update
      blob = ActiveStorage::Blob.find_signed!(params[:id])
      blob.custom_metadata = blob.custom_metadata.merge('alt' => params.expect(:alt).to_s.squish)
      blob.save!

      render json: helpers.media_image_json(blob)
    end

    private

    def check_attachments_enabled
      render_not_found unless LandgrabService.attachments_enabled?
    end

    Source = Data.define(:io, :filename, :content_type, :error)

    # Either an uploaded file or a URL to copy into storage; nil when neither was given
    def image_source
      if params[:file].is_a?(ActionDispatch::Http::UploadedFile)
        uploaded_file_source(params[:file])
      elsif params[:url].present?
        downloaded_source(params[:url].to_s)
      end
    end

    def uploaded_file_source(file)
      Source.new(io: file.tempfile, filename: file.original_filename, content_type: file.content_type,
                 error: file.size > ImageAttachmentValidator::MAX_SIZE ? too_large_message : nil)
    end

    def downloaded_source(url)
      download = ImageDownloadService.download(url, max_bytes: ImageAttachmentValidator::MAX_SIZE)
      Source.new(io: download.io, filename: download.filename, content_type: download.content_type, error: nil)
    rescue ImageDownloadService::Error => e
      Source.new(io: nil, filename: nil, content_type: nil, error: e.message)
    end

    def store(source)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: source.io,
        filename: source.filename,
        content_type: source.content_type,
        metadata: { custom: { alt: alt_text_for(source.filename) } }
      )
      blob.analyze
      blob
    end

    # An alt text given along with the image wins over one derived from the file name
    def alt_text_for(filename)
      params[:alt].to_s.squish.presence || MediaLibrary.default_alt_text(filename)
    end

    def too_large_message
      "must be smaller than #{ActiveSupport::NumberHelper.number_to_human_size(ImageAttachmentValidator::MAX_SIZE)}"
    end

    def invalid_type_message
      'must be a PNG, JPEG, WebP or GIF image'
    end

    def render_error(message, blob = nil)
      blob&.purge
      render json: { error: "Image #{message}" }, status: :unprocessable_content
    end
  end
end
