# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StoredImage do
  let(:png) { file_fixture('images/pixel.png') }
  let(:image_url) { 'https://images.example.com/hero.png' }
  let(:placeholder_url) { 'https://placehold.co/800x400?text=Big%20Wood' }

  def uploaded(fixture, content_type)
    Rack::Test::UploadedFile.new(file_fixture(fixture), content_type)
  end

  def stub_image_download(url = image_url, body: png.binread, content_type: 'image/png')
    stub_request(:get, url).to_return(status: 200, body:, headers: { 'Content-Type' => content_type })
  end

  # A URL saved before uploads were configured, so never downloaded
  def create_project_with_legacy_url
    allow(LandgrabService).to receive(:attachments_enabled?).and_return(false)
    create(:project, hero_image_url: image_url).tap do
      allow(LandgrabService).to receive(:attachments_enabled?).and_return(attachments_enabled)
    end
  end

  before do
    allow(LandgrabService).to receive(:attachments_enabled?).and_return(attachments_enabled)
  end

  context 'when attachments are not enabled' do
    let(:attachments_enabled) { false }

    it 'keeps a given URL without downloading it' do
      project = create(:project, hero_image_url: image_url)

      expect(project.reload.hero_image_url).to eq image_url
    end

    it 'displays the URL' do
      project = create(:project, hero_image_url: image_url)

      expect(project.hero_image_for_display(:web)).to eq image_url
    end

    it 'displays a placeholder when there is no URL' do
      project = create(:project, title: 'Big Wood')

      expect([project.hero_image_for_display, project.hero_image_placeholder?]).to eq [placeholder_url, true]
    end

    it 'clears the URL when removed' do
      project = create(:project, hero_image_url: image_url)

      project.update!(remove_hero_image: true)

      expect(project.reload.hero_image_url).to be_nil
    end
  end

  context 'when attachments are enabled' do
    let(:attachments_enabled) { true }

    it 'stores an uploaded image' do
      project = create(:project, hero_image: uploaded('images/pixel.png', 'image/png'))

      expect(project.reload.hero_image).to be_attached
    end

    it 'displays a stored image rather than its placeholder' do
      project = create(:project, hero_image: uploaded('images/pixel.png', 'image/png'))

      expect([project.hero_image_for_display, project.hero_image_placeholder?]).to eq [project.hero_image, false]
    end

    it 'clears a legacy URL once an image is uploaded' do
      project = create_project_with_legacy_url

      project.update!(hero_image: uploaded('images/pixel.png', 'image/png'))

      expect(project.reload.hero_image_url).to be_nil
    end

    it 'downloads a given URL into storage and clears the URL' do
      stub_image_download
      project = create(:project, hero_image_url: image_url)

      project.reload
      expect([project.hero_image.attached?, project.hero_image.filename.to_s, project.hero_image_url])
        .to eq [true, 'hero.png', nil]
    end

    it 'downloads a given URL only once when validated more than once' do
      stub = stub_image_download
      project = build(:project, hero_image_url: image_url)

      project.valid?
      project.save!

      expect(stub).to have_been_requested.once
    end

    it 'does not download an unchanged legacy URL when saved' do
      project = create_project_with_legacy_url

      project.update!(title: 'Renamed')

      expect(project.reload.hero_image_url).to eq image_url
    end

    it 'does not re-download a stored image when saved' do
      stub = stub_image_download
      project = create(:project, hero_image_url: image_url)

      project.update!(title: 'Renamed', hero_image_url: '')

      expect(stub).to have_been_requested.once
    end

    it 'rejects an upload and a URL given together' do
      project = build(:project, hero_image: uploaded('images/pixel.png', 'image/png'), hero_image_url: image_url)

      expect(project).not_to be_valid
    end

    it 'reports a URL that cannot be downloaded' do
      stub_request(:get, image_url).to_return(status: 404)
      project = build(:project, hero_image_url: image_url)

      project.valid?

      expect(project.errors[:hero_image_url]).to eq ['could not be downloaded (HTTP 404)']
    end

    it 'rejects a downloaded file which is not an image' do
      stub_image_download(body: '<html></html>', content_type: 'text/html')
      project = build(:project, hero_image_url: image_url)

      project.valid?

      expect(project.errors[:hero_image]).to eq ['must be a PNG, JPEG, WebP or GIF image']
    end

    it 'rejects an uploaded SVG' do
      project = build(:project, hero_image: uploaded('images/pixel.svg', 'image/svg+xml'))

      project.valid?

      expect(project.errors[:hero_image]).to eq ['must be a PNG, JPEG, WebP or GIF image']
    end

    it 'rejects an uploaded image which is too large' do
      stub_const('ImageAttachmentValidator::MAX_SIZE', 10)
      project = build(:project, hero_image: uploaded('images/pixel.png', 'image/png'))

      project.valid?

      expect(project.errors[:hero_image]).to eq ['must be smaller than 10 Bytes']
    end

    it 'removes a stored image' do
      project = create(:project, hero_image: uploaded('images/pixel.png', 'image/png'))

      project.update!(remove_hero_image: true)

      expect(project.reload.hero_image).not_to be_attached
    end

    it 'keeps a newly uploaded image even when asked to remove the old one' do
      project = create(:project, hero_image: uploaded('images/pixel.png', 'image/png'))

      project.update!(remove_hero_image: true, hero_image: uploaded('images/pixel.png', 'image/png'))

      expect(project.reload.hero_image).to be_attached
    end
  end
end
