# frozen_string_literal: true

module Admin
  # Immediate uploads for the admin media library, ahead of the owning record being saved.
  class MediaImagesController < ApplicationController
    before_action :check_admin
    before_action :check_attachments_enabled

    rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :render_not_found

    def create
      file = params[:file]
      return render_error('is required') unless file.is_a?(ActionDispatch::Http::UploadedFile)

      error = upload_error(file)
      return render_error(error) if error

      blob = store(file)
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

    def store(file)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file.tempfile,
        filename: file.original_filename,
        content_type: file.content_type,
        metadata: { custom: { alt: MediaLibrary.default_alt_text(file.original_filename) } }
      )
      blob.analyze
      blob
    end

    def upload_error(file)
      return unless file.size > ImageAttachmentValidator::MAX_SIZE

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
