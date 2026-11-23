# frozen_string_literal: true

class Project < ApplicationRecord
  include StoredImage

  has_many :plots, dependent: :restrict_with_exception
  has_many :post_associations, as: :postable, inverse_of: :postable, dependent: :restrict_with_exception
  has_many :posts, through: :post_associations
  has_many :prices, dependent: :restrict_with_exception
  has_many :subscriptions, dependent: :restrict_with_exception

  validates :title, presence: true
  validates :website, url: true, allow_blank: true

  stored_image :hero_image, url_attribute: :hero_image_url, variants: StoredImage::HERO_IMAGE_VARIANTS,
                            placeholder: -> { PlaceholderImageService.url(width: 800, height: 400, text: title) }
  stored_image :logo, url_attribute: :logo_url, variants: StoredImage::LOGO_VARIANTS,
                      placeholder: -> { PlaceholderImageService.url(width: 400, height: 400, text: 'Logo') }

  auto_strip_attributes :title, :hero_image_url, :logo_url, :website, squish: true
  auto_strip_attributes :description, :welcome_text, :subscriber_benefits

  def viewable_by?(user)
    tiles_subscribed_by(user).any?
  end

  def tiles_subscribed_by(user)
    Tile.joins(latest_subscription: :subscriber, plot: :project)
        .where(projects: { id: })
        .where(users: { id: user.id })
  end

  def relevant_posts
    posts.published.order(published_at: :desc)
  end

  def random_available_tile
    random_plot = plots.with_available_tiles.sample
    avail_tiles = random_plot&.tiles&.available
    avail_tiles&.sample
  end
end
