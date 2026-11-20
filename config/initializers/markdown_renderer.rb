# frozen_string_literal: true

# https://stackoverflow.com/a/68098687/1323144
class MarkdownRenderer
  def self.markdown
    # rubocop:disable-next Style/ClassVars
    @@markdown ||= Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      space_after_headers: true,
      tables: true
    )
  end

  def self.renderer
    MarkdownCustomRenderer.new(
      escape_html: false,
      hard_wrap: true,
      safe_links_only: true
    )
  end

  def self.render(text)
    markdown.render(text)
  end
end
