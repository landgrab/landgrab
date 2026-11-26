# frozen_string_literal: true

class Bulletin < ApplicationRecord
  belongs_to :author, class_name: 'User'
  has_many :bulletin_posts, dependent: :destroy
  has_many :posts, through: :bulletin_posts

  validates :subject, presence: true
  validates :posts, presence: true
  validate :posts_share_audience

  auto_strip_attributes :subject, squish: true
  auto_strip_attributes :intro

  # The users who can view every post in the bulletin; only meaningful while the bulletin is valid,
  # because then every post has exactly the same viewers.
  def audience
    first_post = posts.first
    first_post ? first_post.viewers : User.none
  end

  # Anything in the intro or post previews that is too complex for an email, in plain English,
  # for an admin to simplify. A bulletin can't be sent while there are any.
  def content_problems
    problems = describe_unsupported(intro).map { |element| "The intro contains #{element}." }
    posts.each do |post|
      describe_unsupported(post.preview).each { |element| problems << "Post '#{post.title}': the preview contains #{element}." }
    end

    problems
  end

  private

  def describe_unsupported(markdown)
    EmailMarkdownService.unsupported_elements(markdown)
  end

  def posts_share_audience
    return if posts.empty?

    viewer_ids = posts.index_with { |post| post.viewers.ids }

    if viewer_ids.values.map(&:to_set).uniq.many?
      errors.add(:posts, differing_viewers_message(viewer_ids))
    elsif viewer_ids.values.first.empty?
      errors.add(:posts, 'have no viewers, so nobody would receive this bulletin. ' \
                         'Check the posts are associated with a tile, plot, project or team that has subscribers.')
    end
  end

  def differing_viewers_message(viewer_ids)
    counts = viewer_ids.map { |post, ids| "'#{post.title}' (#{ids.size} #{'viewer'.pluralize(ids.size)})" }.join(', ')
    partial = viewer_ids.values.reduce(:|).size - viewer_ids.values.reduce(:&).size

    "must all have exactly the same viewers, but they don't: #{counts}. " \
      "#{partial} #{'user'.pluralize(partial)} can view some of them but not all. " \
      'The easiest fix is to give every post the same associations.'
  end
end
