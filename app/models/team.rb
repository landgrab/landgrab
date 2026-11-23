# frozen_string_literal: true

class Team < ApplicationRecord
  include StoredImage

  has_many :users, dependent: :nullify
  has_many :post_associations, as: :postable, inverse_of: :postable, dependent: :restrict_with_exception
  has_many :posts, through: :post_associations

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  stored_image :logo, url_attribute: :logo_url, variants: StoredImage::LOGO_VARIANTS,
                      placeholder: -> { PlaceholderImageService.url(width: 400, height: 400, text: 'Logo') }

  before_validation :normalize_slug

  auto_strip_attributes :title, :slug, :logo_url, :website, :description, squish: true

  def normalize_slug
    self.slug = slug.present? ? slug&.parameterize : title&.parameterize
  end

  # Tiles redeemed by members through a usable subscription
  def team_tiles
    Tile.joins(:latest_subscription)
        .merge(Subscription.usable)
        .where(subscriptions: { redeemer_id: users.select(:id) })
  end

  def team_plots
    Plot.where(id: team_tiles.reorder(nil).select(:plot_id))
  end

  def relevant_posts
    posts.published.order(published_at: :desc)
  end

  def to_param
    slug
  end
end
