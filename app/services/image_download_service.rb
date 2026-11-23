# frozen_string_literal: true

require 'net/http'

# Downloads an image from an external URL so it can be stored rather than linked to
class ImageDownloadService
  class Error < StandardError; end

  Download = Data.define(:io, :filename, :content_type)

  MAX_REDIRECTS = 3
  TIMEOUT_SECONDS = 10
  NETWORK_ERRORS = [
    IOError,
    Net::HTTPBadResponse,
    Net::ProtocolError,
    OpenSSL::SSL::SSLError,
    SocketError,
    SystemCallError,
    Timeout::Error
  ].freeze

  class << self
    def download(url, max_bytes:)
      uri = parse_uri(url)

      (MAX_REDIRECTS + 1).times do
        result = fetch(uri, max_bytes)
        return result if result.is_a?(Download)

        uri = parse_uri(result, base: uri)
      end

      raise Error, 'redirected too many times'
    rescue *NETWORK_ERRORS
      raise Error, 'could not be downloaded'
    end

    private

    def parse_uri(url, base: nil)
      uri = base ? URI.join(base, url) : URI.parse(url)
      raise Error, 'must be an http or https URL' unless uri.is_a?(URI::HTTP) && uri.host.present?

      uri
    rescue URI::Error
      raise Error, 'is not a valid URL'
    end

    # Returns a Download, or the location to follow when redirected
    def fetch(uri, max_bytes)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                          open_timeout: TIMEOUT_SECONDS,
                                          read_timeout: TIMEOUT_SECONDS) do |http|
        http.request(Net::HTTP::Get.new(uri)) do |response|
          return handle_response(response, uri, max_bytes)
        end
      end
    end

    def handle_response(response, uri, max_bytes)
      case response
      when Net::HTTPRedirection
        response['location'].presence || raise(Error, 'redirected without a location')
      when Net::HTTPSuccess
        Download.new(io: read_body(response, max_bytes), filename: filename_for(uri), content_type: response.content_type)
      else
        raise Error, "could not be downloaded (HTTP #{response.code})"
      end
    end

    def read_body(response, max_bytes)
      io = StringIO.new
      response.read_body do |chunk|
        io.write(chunk)
        raise Error, "must be smaller than #{ActiveSupport::NumberHelper.number_to_human_size(max_bytes)}" if io.size > max_bytes
      end
      io.rewind
      io
    end

    def filename_for(uri)
      name = File.basename(uri.path.to_s)
      name.present? && name != '/' ? name : 'image'
    end
  end
end
