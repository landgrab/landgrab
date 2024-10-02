# frozen_string_literal: true

class MarkdownCustomRenderer < Redcarpet::Render::HTML
  YOUTUBE_REGEX = %r{^(?:https?:)?(?://)?(?:youtu\.be/|(?:www\.|m\.)?youtube\.com/(?:watch|v|embed|shorts)(?:\.php)?(?:\?.*v=|/))([a-zA-Z0-9_-]{7,15})(?:[?&][a-zA-Z0-9_-]+=[a-zA-Z0-9_-]+)*$}

  def block_quote(quote)
    %(<blockquote class="blockquote">#{quote}</blockquote>)
  end

  def table(header, body)
    "<table class=\"table\">#{header}#{body}</table>"
  end

  def image(link, title, alt_text)
    %(<img src="#{link}" title="#{title}" alt="#{alt_text}" class="rounded img-fluid" />)
  end

  def autolink(link, link_type)
    case link_type
    when :url then url_link(link)
    when :email then email_link(link)
    else raise "Unexpected link_type: #{link_type}"
    end
  end

  def url_link(link)
    slug = link.scan(YOUTUBE_REGEX).last&.first
    return youtube_embed(slug) if slug.present?

    normal_link(link)
  end

  def youtube_embed(slug)
    <<-HTML.squish
      <div class="ratio ratio-16x9">
        <iframe width="560" height="315"
                src="https://www.youtube.com/embed/#{slug}"
                title="Video"
                frameborder="0"
                allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                allowfullscreen></iframe>
      </div>
    HTML
  end

  def normal_link(link)
    "<a href=\"#{link}\">#{link}</a>"
  end

  def email_link(email)
    "<a href=\"mailto:#{email}\">#{email}</a>"
  end
end
