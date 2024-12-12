# frozen_string_literal: true

class Project < ApplicationRecord
  has_many :plots, dependent: :restrict_with_exception
  has_many :post_associations, as: :postable, inverse_of: :postable, dependent: :restrict_with_exception
  has_many :posts, through: :post_associations
  has_many :prices, dependent: :restrict_with_exception
  has_many :subscriptions, dependent: :restrict_with_exception

  validates :title, presence: true
  validates :hero_image_url, :logo_url, :website, url: true, allow_blank: true

  auto_strip_attributes :title, squish: true
  auto_strip_attributes :description, :welcome_text, :subscriber_benefits

  def viewable_by?(user)
    tiles_subscribed_by(user).any?
  end

  def tiles_subscribed_by(user)
    Tile.joins(latest_subscription: :subscriber, plot: :project)
        .where(projects: { id: })
        .where(users: { id: user.id })
  end

  def hero_image_url_fallback
    hero_image_url.presence || "https://placehold.co/800x400?text=#{title}"
  end

  def relevant_posts
    posts.published.order(published_at: :desc)
  end

  def random_available_tile
    plots.with_available_tiles.sample&.tiles&.available&.sample
  end
end
