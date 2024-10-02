# frozen_string_literal: true

# https://stackoverflow.com/a/68098687/1323144
class MarkdownUnlinkedRenderer
  def self.markdown_unlinked
    # rubocop:disable Style/ClassVars
    @@markdown ||= Redcarpet::Markdown.new(
      renderer_unlinked,
      autolink: false,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      space_after_headers: true,
      tables: true
    )
    # rubocop:enable Style/ClassVars
  end

  def self.renderer_unlinked
    MarkdownCustomUnlinkedRenderer.new(
      escape_html: false,
      hard_wrap: true
    )
  end

  def self.render_unlinked(text)
    markdown_unlinked.render(text)
  end
end
