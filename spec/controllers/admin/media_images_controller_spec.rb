# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::MediaImagesController do
  let(:admin) { create(:user, admin: true) }
  let(:attachments_enabled) { true }

  before do
    allow(LandgrabService).to receive(:attachments_enabled?).and_return(attachments_enabled)
  end

  def image_upload(name = 'pixel.png', content_type = 'image/png')
    Rack::Test::UploadedFile.new(file_fixture("images/#{name}"), content_type)
  end

  describe 'POST create' do
    context 'when signed in as an admin' do
      before { sign_in(admin, scope: :user) }

      it 'stores the image as an unattached upload' do
        expect { post :create, params: { file: image_upload } }.to change(ActiveStorage::Blob, :count).by(1)
      end

      it 'describes the stored image for the editor' do
        post :create, params: { file: image_upload }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to include('filename' => 'pixel.png', 'alt' => 'pixel')
      end

      it 'includes the image dimensions' do
        post :create, params: { file: image_upload }

        expect(response.parsed_body).to include('width' => 1, 'height' => 1)
      end

      it 'returns web and full URLs that differ, and a thumbnail' do
        post :create, params: { file: image_upload }

        urls = response.parsed_body.values_at('thumb_url', 'web_url', 'full_url')
        expect(urls.uniq.size).to eq 3
      end

      it 'rejects files that are not images' do
        file = Rack::Test::UploadedFile.new(StringIO.new('just text'), 'text/plain', original_filename: 'notes.txt')

        expect { post :create, params: { file: } }.not_to change(ActiveStorage::Blob, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']).to include('must be a PNG, JPEG, WebP or GIF image')
      end

      it 'rejects images over the size limit' do
        stub_const('ImageAttachmentValidator::MAX_SIZE', 10.bytes)

        expect { post :create, params: { file: image_upload } }.not_to change(ActiveStorage::Blob, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']).to include('must be smaller than')
      end

      it 'uses the alt text given with the upload instead of the file name' do
        post :create, params: { file: image_upload, alt: '  A path   through the woods ' }

        expect(response.parsed_body['alt']).to eq 'A path through the woods'
      end

      it 'requires a file or URL' do
        post :create

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when signed in as a non-admin' do
      before { sign_in(create(:user), scope: :user) }

      it 'does not store anything' do
        expect { post :create, params: { file: image_upload } }.not_to change(ActiveStorage::Blob, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when attachments are not enabled' do
      let(:attachments_enabled) { false }

      before { sign_in(admin, scope: :user) }

      it 'does not store anything' do
        expect { post :create, params: { file: image_upload } }.not_to change(ActiveStorage::Blob, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST create with an image URL' do
    before do
      sign_in(admin, scope: :user)
      stub_request(:get, url).to_return(body: file_fixture('images/pixel.png').binread, headers: { 'Content-Type' => 'image/png' })
    end

    let(:url) { 'https://images.example.com/path/woodland-edge.png' }

    it 'copies the image into storage' do
      expect { post :create, params: { url: } }.to change(ActiveStorage::Blob, :count).by(1)
    end

    it 'describes the stored image with alt text from the file name' do
      post :create, params: { url: }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include('filename' => 'woodland-edge.png', 'alt' => 'woodland edge')
    end

    it 'uses the alt text given with the URL' do
      post :create, params: { url:, alt: 'A woodland edge' }

      expect(response.parsed_body['alt']).to eq 'A woodland edge'
    end

    it 'rejects URLs which cannot be downloaded, storing nothing' do
      stub_request(:get, url).to_return(status: 404)

      expect { post :create, params: { url: } }.not_to change(ActiveStorage::Blob, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to include('could not be downloaded')
    end

    it 'rejects URLs which are not images, storing nothing' do
      stub_request(:get, url).to_return(body: 'just text', headers: { 'Content-Type' => 'text/plain' })

      expect { post :create, params: { url: } }.not_to change(ActiveStorage::Blob, :count)
      expect(response.parsed_body['error']).to include('must be a PNG, JPEG, WebP or GIF image')
    end

    it 'rejects images over the size limit' do
      stub_const('ImageAttachmentValidator::MAX_SIZE', 10.bytes)

      expect { post :create, params: { url: } }.not_to change(ActiveStorage::Blob, :count)
      expect(response.parsed_body['error']).to include('must be smaller than')
    end
  end

  describe 'PATCH update' do
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: file_fixture('images/pixel.png').open, filename: 'pixel.png', content_type: 'image/png'
      )
    end

    before { sign_in(admin, scope: :user) }

    it 'saves the alt text on the image' do
      patch :update, params: { id: blob.signed_id, alt: '  A   path through the woods ' }

      expect(response).to have_http_status(:ok)
      expect(blob.reload.custom_metadata['alt']).to eq 'A path through the woods'
    end

    it 'keeps the image dimensions' do
      blob.analyze

      patch :update, params: { id: blob.signed_id, alt: 'A path' }

      expect(blob.reload.metadata).to include('width' => 1, 'height' => 1)
    end

    it 'does not accept an unsigned id' do
      patch :update, params: { id: blob.id, alt: 'x' }

      expect(response).to have_http_status(:not_found)
    end
  end
end
