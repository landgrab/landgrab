# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalImageStorageService do
  let(:png) { file_fixture('images/pixel.png') }
  let(:image_url) { 'https://images.example.com/image.png' }
  let(:dead_url) { 'https://images.example.com/dead.png' }

  def stub_image_download(url = image_url, body: png.binread, content_type: 'image/png')
    stub_request(:get, url).to_return(status: 200, body:, headers: { 'Content-Type' => content_type })
  end

  # A record saved before uploads were configured, so its URLs were never downloaded
  def create_with_legacy_urls(factory, **attributes)
    allow(LandgrabService).to receive(:attachments_enabled?).and_return(false)
    create(factory, **attributes).tap do
      allow(LandgrabService).to receive(:attachments_enabled?).and_return(true)
    end
  end

  # Leave only the records each example creates with external images (CI's database is seeded)
  def clear_existing_image_urls
    # rubocop:disable Rails/SkipsModelValidations
    Project.update_all(hero_image_url: nil, logo_url: nil)
    Plot.update_all(hero_image_url: nil)
    Team.update_all(logo_url: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def summary(result)
    { stored: result.stored, skipped: result.skipped, failures: result.failures.map(&:to_h) }
  end

  before do
    clear_existing_image_urls
    allow(LandgrabService).to receive(:attachments_enabled?).and_return(true)
    stub_image_download
    stub_request(:get, dead_url).to_return(status: 404)
  end

  describe '.store_all' do
    context 'with external images on every kind of record' do
      let!(:project) { create_with_legacy_urls(:project, hero_image_url: image_url, logo_url: image_url) }
      let!(:plot) { create_with_legacy_urls(:plot, hero_image_url: image_url) }
      let!(:team) { create_with_legacy_urls(:team, logo_url: image_url) }

      it 'stores each image' do
        described_class.store_all

        expect([project.reload.hero_image, project.logo, plot.reload.hero_image, team.reload.logo].map(&:attached?))
          .to eq [true, true, true, true]
      end

      it 'clears each URL' do
        described_class.store_all

        expect([project.reload.hero_image_url, project.logo_url, plot.reload.hero_image_url, team.reload.logo_url])
          .to eq [nil, nil, nil, nil]
      end

      it 'reports what it stored' do
        expect(described_class.store_all.stored).to eq [
          "Project #{project.id} (#{project.hashid}) hero_image", "Project #{project.id} (#{project.hashid}) logo",
          "Plot #{plot.id} (#{plot.hashid}) hero_image", "Team #{team.id} (#{team.slug}) logo"
        ]
      end

      it 'stores nothing more when run again' do
        described_class.store_all

        expect(summary(described_class.store_all)).to eq(stored: [], skipped: 0, failures: [])
      end
    end

    it 'skips images which are already stored, without downloading them' do
      project = create(:project, logo: { io: png.open, filename: 'pixel.png', content_type: 'image/png' })
      Project.where(id: project.id).update_all(logo_url: image_url) # rubocop:disable Rails/SkipsModelValidations

      expect(summary(described_class.store_all)).to eq(stored: [], skipped: 1, failures: [])
      expect(a_request(:get, image_url)).not_to have_been_made
    end

    it 'ignores records without a URL' do
      create(:project)

      expect(summary(described_class.store_all)).to eq(stored: [], skipped: 0, failures: [])
    end

    context 'when an image fails to download' do
      let!(:project) { create_with_legacy_urls(:project, hero_image_url: dead_url, logo_url: image_url) }

      it 'reports the failure' do
        expect(described_class.store_all.failures.map(&:to_h)).to eq [
          { label: "Project #{project.id} (#{project.hashid}) hero_image",
            error: 'Hero image url could not be downloaded (HTTP 404)' }
        ]
      end

      it 'keeps its URL and goes on to store the other images' do
        described_class.store_all

        expect([project.reload.hero_image.attached?, project.hero_image_url, project.logo.attached?])
          .to eq [false, dead_url, true]
      end
    end

    it 'reports a failure when the URL is not an image' do
      stub_image_download(body: '<html></html>', content_type: 'text/html')
      plot = create_with_legacy_urls(:plot, hero_image_url: image_url)

      expect(described_class.store_all.failures.map(&:error)).to eq ['Hero image must be a PNG, JPEG, WebP or GIF image']
      expect(plot.reload.hero_image_url).to eq image_url
    end

    context 'with a dry run' do
      let!(:team) { create_with_legacy_urls(:team, logo_url: image_url) }

      it 'lists the images it would store' do
        expect(described_class.store_all(dry_run: true).stored).to eq ["Team #{team.id} (#{team.slug}) logo"]
      end

      it 'neither downloads nor stores anything' do
        described_class.store_all(dry_run: true)

        expect([team.reload.logo_url, team.logo.attached?]).to eq [image_url, false]
        expect(a_request(:get, image_url)).not_to have_been_made
      end
    end

    context 'when attachments are not enabled' do
      let!(:team) { create_with_legacy_urls(:team, logo_url: image_url) }

      before { allow(LandgrabService).to receive(:attachments_enabled?).and_return(false) }

      it 'raises without changing anything' do
        expect { described_class.store_all }.to raise_error(described_class::AttachmentsDisabledError)
        expect(team.reload.logo_url).to eq image_url
      end
    end
  end
end
