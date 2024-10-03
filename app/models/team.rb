# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :post_associations, as: :postable, inverse_of: :postable, dependent: :restrict_with_exception
  has_many :posts, through: :post_associations

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :normalize_slug

  def normalize_slug
    self.slug = slug.present? ? slug&.parameterize : title&.parameterize
  end

  def logo_url_fallback
    logo_url.presence || "https://placehold.co/800x400?text=#{title}"
  end

  def relevant_posts
    posts.published.order(published_at: :desc)
  end

  def to_param
    slug
  end
end
