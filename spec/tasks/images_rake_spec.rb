# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'images:store_external_urls' do # rubocop:disable RSpec/DescribeClass
  let(:png) { file_fixture('images/pixel.png') }
  let(:logo_url) { 'https://images.example.com/logo.png' }
  let(:dead_url) { 'https://images.example.com/dead.png' }

  def run_task(dry_run: false)
    Rails.application.load_tasks unless Rake::Task.task_defined?('images:store_external_urls')
    ENV['DRY_RUN'] = '1' if dry_run
    Rake::Task['images:store_external_urls'].reenable
    Rake::Task['images:store_external_urls'].invoke
  ensure
    ENV.delete('DRY_RUN')
  end

  # Leave only the records each example creates with external images (CI's database is seeded)
  def clear_existing_image_urls
    # rubocop:disable Rails/SkipsModelValidations
    Project.update_all(hero_image_url: nil, logo_url: nil)
    Plot.update_all(hero_image_url: nil)
    Team.update_all(logo_url: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end

  # A team saved before uploads were configured, so its logo URL was never downloaded
  def create_team_with_legacy_logo(url)
    allow(LandgrabService).to receive(:attachments_enabled?).and_return(false)
    create(:team, logo_url: url).tap do
      allow(LandgrabService).to receive(:attachments_enabled?).and_return(attachments_enabled)
    end
  end

  before do
    clear_existing_image_urls
    allow(LandgrabService).to receive(:attachments_enabled?).and_return(attachments_enabled)
    stub_request(:get, logo_url).to_return(body: png.binread, headers: { 'Content-Type' => 'image/png' })
    stub_request(:get, dead_url).to_return(status: 404)
  end

  context 'when attachments are enabled' do
    let(:attachments_enabled) { true }
    let!(:team) { create_team_with_legacy_logo(logo_url) }

    it 'stores the images and reports the counts and each failure' do
      dead_team = create_team_with_legacy_logo(dead_url)

      expect { run_task }.to output(<<~OUTPUT).to_stdout
        Stored 1 image(s), skipped 0 already stored, 1 failed.
          Team #{dead_team.id} (#{dead_team.slug}) logo: Logo url could not be downloaded (HTTP 404)
      OUTPUT
    end

    it 'lists what it would store on a dry run, without storing it' do
      expect { run_task(dry_run: true) }.to output(<<~OUTPUT).to_stdout
        Dry run: would store 1 image(s), skipping 0 already stored.
          Team #{team.id} (#{team.slug}) logo
      OUTPUT
      expect(team.reload.logo_url).to eq logo_url
    end
  end

  context 'when attachments are not enabled' do
    let(:attachments_enabled) { false }

    it 'does nothing' do
      team = create_team_with_legacy_logo(logo_url)

      expect { run_task }.to output(/Nothing done/).to_stdout
      expect(team.reload.logo_url).to eq logo_url
    end
  end
end
