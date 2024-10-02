class MarkdownCustomUnlinkedRenderer < MarkdownCustomRenderer
  def link(link, title, content)
    content
  end

  def autolink(link, _link_type)
    link
  end
end
