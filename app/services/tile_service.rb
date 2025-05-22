# frozen_string_literal: true

class TileService
  def self.distance_between_tile_midpoints_human(tile1, tile2)
    distance_in_meters = distance_between_tile_midpoints(tile1, tile2)
    return '0 m' if distance_in_meters.round.zero?

    return "#{distance_in_meters.round} m" if distance_in_meters < 750

    distance_in_km = distance_in_meters / 1000

    return "#{distance_in_km.round(2)} km" if distance_in_km < 10

    "#{distance_in_km.round} km"
  end

  def self.distance_between_tile_midpoints(tile1, tile2)
    tile1.midpoint_geo.distance(tile2.midpoint_geo)
  end
end
