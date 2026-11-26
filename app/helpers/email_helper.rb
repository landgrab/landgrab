# frozen_string_literal: true

module EmailHelper
  # Markdown as simple, sanitised email HTML (see EmailMarkdownService)
  def email_markdown(text)
    EmailMarkdownService.render(text)
  end
end
