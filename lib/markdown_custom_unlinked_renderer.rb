# frozen_string_literal: true

class MarkdownCustomUnlinkedRenderer < MarkdownCustomRenderer
  def link(_link, _title, content)
    content
  end

  def autolink(link, _link_type)
    link
  end
end
