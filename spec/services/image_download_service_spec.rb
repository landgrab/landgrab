# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageDownloadService do
  let(:url) { 'https://images.example.com/path/photo.jpg' }

  def download(from = url, max_bytes: 1.megabyte)
    described_class.download(from, max_bytes:)
  end

  it 'returns the downloaded body, filename and content type' do
    stub_request(:get, url).to_return(body: 'jpeg-bytes', headers: { 'Content-Type' => 'image/jpeg' })

    result = download

    expect([result.io.read, result.filename, result.content_type]).to eq ['jpeg-bytes', 'photo.jpg', 'image/jpeg']
  end

  it 'names the file "image" when the URL has no path' do
    stub_request(:get, 'https://images.example.com/').to_return(body: 'bytes')

    expect(download('https://images.example.com/').filename).to eq 'image'
  end

  it 'follows relative redirects' do
    stub_request(:get, url).to_return(status: 302, headers: { 'Location' => '/moved.png' })
    stub_request(:get, 'https://images.example.com/moved.png').to_return(body: 'png-bytes')

    expect(download.filename).to eq 'moved.png'
  end

  it 'gives up after too many redirects' do
    stub_request(:get, url).to_return(status: 302, headers: { 'Location' => url })

    expect { download }.to raise_error(described_class::Error, 'redirected too many times')
  end

  it 'rejects URLs which are not http or https' do
    expect { download('ftp://images.example.com/photo.jpg') }
      .to raise_error(described_class::Error, 'must be an http or https URL')
  end

  it 'rejects bodies larger than the limit' do
    stub_request(:get, url).to_return(body: 'x' * 11)

    expect { download(max_bytes: 10) }.to raise_error(described_class::Error, 'must be smaller than 10 Bytes')
  end

  it 'reports unsuccessful responses' do
    stub_request(:get, url).to_return(status: 500)

    expect { download }.to raise_error(described_class::Error, 'could not be downloaded (HTTP 500)')
  end

  it 'reports network failures' do
    stub_request(:get, url).to_timeout

    expect { download }.to raise_error(described_class::Error, 'could not be downloaded')
  end
end
