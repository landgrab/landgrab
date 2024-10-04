# frozen_string_literal: true

class Plot < ApplicationRecord
  belongs_to :project, optional: true
  has_many :tiles, dependent: :nullify
  has_many :post_associations, as: :postable, inverse_of: :postable, dependent: :restrict_with_exception
  has_many :posts, through: :post_associations

  default_scope { order(:id) }

  validates :title, presence: true
  validates :polygon, presence: true
  validates :hero_image_url, url: true, allow_blank: true

  validate :validate_bounding_box_dimensions
  validate :validate_overlapping_polygons

  auto_strip_attributes :title, squish: true

  enum :tile_population_status, {
    pending: 0,
    in_progress: 1,
    succeeded: 2,
    errored: 3
  }, prefix: true

  scope :with_available_tiles, -> { left_joins(tiles: :latest_subscription).where(latest_subscription: { id: nil }) }

  MAX_BOUNDING_BOX_DIMENSION = 0.005
  DEFAULT_COORDS = [51.4778, -0.0014].freeze # Greenwich Observatory

  def centroid_coords
    RGeo::Cartesian::PointImpl.new(RGeo::Cartesian::Factory.new, polygon.centroid.x, polygon.centroid.y)
  end

  def centroid_coords_display
    [centroid_coords.x, centroid_coords.y].map { |x| format('%.6f', x) }.join(', ')
  end

  def bounding_box
    x_coords = polygon.coordinates[0].pluck(0)
    y_coords = polygon.coordinates[0].pluck(1)

    northeast = RGeo::Cartesian::PointImpl.new(RGeo::Cartesian::Factory.new, x_coords.max, y_coords.max)
    southwest = RGeo::Cartesian::PointImpl.new(RGeo::Cartesian::Factory.new, x_coords.min, y_coords.min)

    RGeo::Cartesian::BoundingBox.create_from_points(southwest, northeast)
  end

  def area
    # See https://gis.stackexchange.com/questions/153192
    query = ActiveRecord::Base.sanitize_sql(['SELECT
      ST_Area(
        geography(
          ST_Transform(
            ST_GeomFromText(?, 4326),
            4326
          )
        )
      ) AS area;
    ', polygon.as_json])

    ActiveRecord::Base.connection.execute(query)[0]['area'].to_f
  end

  def area_formatted_unsquared
    if area <= 100_000
      "#{format('%.1f', area)} m"
    elsif area <= 1_000_000
      "#{format('%.2g', area / 1_000_000)} km"
    end
  end

  def area_formatted_acres
    "#{format('%.3f', area / 4046.86)} acres"
  end

  def coordinates_display
    "POLYGON ((#{polygon.coordinates[0].map { |coord| coord.map { |x| format('%.6f', x) }.join(' ') }.join(', ')}))"
  end

  def non_subscribed_tiles
    tiles.where.missing(:latest_subscription)
  end

  def validate_bounding_box_dimensions
    return if polygon.nil?

    errors.add(:polygon, 'is too wide') if bounding_box.x_span > MAX_BOUNDING_BOX_DIMENSION
    errors.add(:polygon, 'is too high') if bounding_box.y_span > MAX_BOUNDING_BOX_DIMENSION
  end

  def validate_overlapping_polygons
    overlaps = overlapping_polygons
    return if overlaps.blank?

    errors.add(:polygon, "intersects with other plot(s) - #{overlaps.map(&:title).join(', ')}")
  end

  def overlapping_polygons
    return nil if polygon.nil?

    Plot
      .select('plots.id, plots.title, plots.polygon')
      .joins('INNER JOIN plots p2 ON plots.id != p2.id')
      .where('ST_Intersects(plots.polygon, ST_GeomFromText(?, 0))', polygon.as_json)
      .where.not(id:)
      .distinct
  end

  def viewable_by?(user)
    tiles_subscribed_by(user).any?
  end

  def tiles_subscribed_by(user)
    tiles.joins(latest_subscription: :subscriber).where(users: { id: user.id }).includes(:latest_subscription)
  end

  def tiles_for_map(include_tile: nil)
    # returns 250 (or 251) tiles, sampling a balance of subscribed vs avaliable tiles
    subscribed = tiles.includes(:latest_subscription).unavailable.sample(100)
    available = tiles.includes(:latest_subscription).where.not(id: subscribed.map(&:id)).sample(150)
    ([include_tile] + subscribed + available).compact.uniq
  end

  def hero_image_url_fallback
    hero_image_url.presence || "https://placehold.co/800x400?text=#{title}"
  end

  def relevant_posts
    [self, project].compact.map { |x| x.posts.published }.flatten.uniq.sort_by(&:published_at)
  end
end
