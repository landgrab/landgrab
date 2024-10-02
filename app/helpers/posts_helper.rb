# frozen_string_literal: true

module PostsHelper
  def markdown(text)
    return nil if text.blank?

    # rubocop:disable Rails/OutputSafety
    MarkdownRenderer.render(text).html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def markdown_unlinked(text)
    return nil if text.blank?

    # rubocop:disable Rails/OutputSafety
    MarkdownUnlinkedRenderer.render_unlinked(text).html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def linkify_tiles(string)
    mentioned_tiles = Post.new(body: string).mentioned_tiles

    mentioned_tiles.each do |tile|
      string.gsub!(
        %r{///(#{tile.w3w})},
        "[///\\1](#{Rails.application.routes.url_helpers.tile_url(tile)})"
      )
    end

    string
  end

  def render_post_published_state(post)
    capture do
      if post.published_at.present?
        if post.published_at.future?
          concat(content_tag(:span, 'SCHEDULED', class: 'badge bg-warning'))
        else
          concat(content_tag(:span, 'PUBLISHED', class: 'badge bg-success'))
        end
        concat(' ')
        concat(post.published_at.to_fs(:short))
      else
        concat(content_tag(:span, 'DRAFT', class: 'badge bg-danger'))
        concat(' (not scheduled)')
      end
    end
  end
end
