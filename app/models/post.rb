# frozen_string_literal: true

class Post < ApplicationRecord
  include MediaLibrary

  attr_accessor :publish_immediately

  belongs_to :author, class_name: 'User', inverse_of: :posts_authored

  has_many :post_associations, dependent: :destroy
  has_many :associated_teams, through: :post_associations, source: :postable, source_type: 'Team'
  has_many :associated_projects, through: :post_associations, source: :postable, source_type: 'Project'
  has_many :associated_plots, through: :post_associations, source: :postable, source_type: 'Plot'
  has_many :associated_tiles, through: :post_associations, source: :postable, source_type: 'Tile'
  has_many :post_views, dependent: :destroy
  has_many :comments, dependent: :restrict_with_exception

  if LandgrabService.attachments_enabled?
    has_one_attached :hero_image do |attachable|
      attachable.variant :thumb, resize_to_fill: [100, 100]
    end
  end

  media_library

  validates :title, presence: true
  validates :body, presence: true

  scope :published, ->(value = true) { value ? where('published_at IS NOT NULL AND published_at <= ?', Time.zone.now) : where('published_at IS NULL OR published_at > ?', Time.zone.now) }
  scope :title, ->(value) { where('posts.title ILIKE ?', "%#{value}%") }
  scope :body, ->(value) { where('posts.body ILIKE ?', "%#{value}%") }
  scope :preview, ->(value) { where('posts.preview ILIKE ?', "%#{value}%") }

  auto_strip_attributes :title, squish: true
  auto_strip_attributes :body, :preview

  W3W_REGEX = %r{/{3}([a-z]+\.[a-z]+\.[a-z]+)}

  def mentioned_w3w
    body.scan(W3W_REGEX).uniq.map(&:first)
  end

  def mentioned_tiles
    Tile.where(w3w: mentioned_w3w)
  end

  # Associates any tiles mentioned in the body that are not already associated
  def associate_mentioned_tiles
    (mentioned_tiles - associated_tiles).each do |tile|
      post_associations.create(postable: tile)
    end
  end

  def viewed_by_users
    User.joins(:post_views).where(post_views: { post_id: id }).distinct
  end

  # Viewable if user has subscribed to any associated tile
  def viewable_by?(user)
    # Handle association types separately to optimise N+1 queries
    viewable_by_via_tile?(user) ||
      viewable_by_via_plot?(user) ||
      viewable_by_via_project?(user) ||
      viewable_by_via_team?(user)
  end

  def viewable_by_via_tile?(user)
    post_associations.where(postable_type: 'Tile')
                     .includes(postable: :latest_subscription)
                     .any? { |a| a.postable.viewable_by?(user) }
  end

  def viewable_by_via_plot?(user)
    post_associations.where(postable_type: 'Plot')
                     .includes(postable: { tiles: :latest_subscription })
                     .any? { |a| a.postable.viewable_by?(user) }
  end

  def viewable_by_via_project?(user)
    post_associations.where(postable_type: 'Project')
                     .any? { |a| a.postable.viewable_by?(user) }
  end

  def viewable_by_via_team?(user)
    return false if user.team_id.nil?

    post_associations.where(postable_type: 'Team', postable_id: user.team_id)
                     .any?
  end
end
