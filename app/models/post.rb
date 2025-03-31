# frozen_string_literal: true

class Post < ApplicationRecord
  attr_accessor :publish_immediately

  belongs_to :author, class_name: 'User', inverse_of: :posts_authored

  has_many :post_associations, dependent: :destroy
  has_many :post_views, dependent: :destroy
  has_many :comments, dependent: :restrict_with_exception

  validates :title, presence: true
  validates :body, presence: true

  scope :published, ->(value = true) { value ? where('published_at IS NOT NULL AND published_at <= ?', Time.zone.now) : where('published_at IS NULL OR published_at > ?', Time.zone.now) }
  scope :title, ->(value) { where('posts.title ILIKE ?', "%#{value}%") }
  scope :body, ->(value) { where('posts.body ILIKE ?', "%#{value}%") }
  scope :preview, ->(value) { where('posts.preview ILIKE ?', "%#{value}%") }

  auto_strip_attributes :title, squish: true
  auto_strip_attributes :body, :preview

  W3W_REGEX = %r{/{3}([a-z]+\.[a-z]+\.[a-z]+)}

  def associated_tiles
    post_associations.where(postable_type: 'Tile').includes(:postable).map(&:postable)
  end

  def associated_plots
    post_associations.where(postable_type: 'Plot').includes(:postable).map(&:postable)
  end

  def associated_projects
    post_associations.where(postable_type: 'Project').includes(:postable).map(&:postable)
  end

  def mentioned_w3w
    body.scan(W3W_REGEX).uniq.map(&:first)
  end

  def mentioned_tiles
    Tile.where(w3w: mentioned_w3w)
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
