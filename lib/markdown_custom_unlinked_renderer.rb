# frozen_string_literal: true

class MarkdownCustomUnlinkedRenderer < MarkdownCustomRenderer
  def link(_link, _title, content)
    content
  end

  # Override to still embed YouTube vids, but not linkify normal URLs
  def url_link(link)
    slug = link.scan(YOUTUBE_REGEX).last&.first
    return youtube_embed(slug) if slug.present?

    link
  end
end
