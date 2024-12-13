# frozen_string_literal: true

namespace :polygon do
  desc 'Generate a polygon string from a list of W3W addresses'
  task from_w3w_list: :environment do
    [
      {
        title: 'First Polygon',
        w3w_list: %w[a.a.a b.b.b c.c.c]
      }
      # ...
    ].each do |plot|
      puts "Title: #{plot[:title]}"
      polygon = PolygonService.polygon_from_w3w_list(plot[:w3w_list])
      puts "Polygon: #{polygon}"
    end
  end
end
