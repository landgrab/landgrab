# frozen_string_literal: true

class PlaceholderImageService
  class << self
    def url(width:, height:, text:)
      "https://placehold.co/#{width}x#{height}?text=#{ERB::Util.url_encode(text)}"
    end
  end
end
