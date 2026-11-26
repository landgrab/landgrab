# frozen_string_literal: true

# Turns markdown into HTML that is safe and simple enough for an email. Only the basics are
# supported: paragraphs, line breaks, bold, italic, links, lists and images. Anything else
# (tables, code, headings, quotes, raw HTML such as YouTube embeds) is reported by
# #unsupported_elements so it can be simplified, never silently dropped.
class EmailMarkdownService
  ALLOWED_TAGS = %w[p br strong em a ul ol li img].freeze
  ALLOWED_ATTRIBUTES = %w[href src alt title].freeze

  DESCRIPTIONS = {
    'table' => 'a table', 'thead' => 'a table', 'tbody' => 'a table', 'tr' => 'a table', 'th' => 'a table', 'td' => 'a table',
    'pre' => 'code', 'code' => 'code',
    'iframe' => 'an embedded video or frame',
    'blockquote' => 'a quote',
    'h1' => 'a heading', 'h2' => 'a heading', 'h3' => 'a heading', 'h4' => 'a heading', 'h5' => 'a heading', 'h6' => 'a heading'
  }.freeze

  class << self
    # Sanitised HTML with relative links and images made absolute
    def render(markdown)
      return ''.html_safe if markdown.blank?

      fragment = fragment_for(markdown)
      fragment.css('[href], [src]').each { |element| absolutise(element) }

      ActionController::Base.helpers.sanitize(fragment.to_html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
    end

    # Plain-English names of the unsupported things in the markdown, such as ["a table", "code"]
    def unsupported_elements(markdown)
      return [] if markdown.blank?

      elements = fragment_for(markdown).css('*').reject { |element| ALLOWED_TAGS.include?(element.name) }
      elements = elements.reject { |element| element.name == 'div' && element.at_css('iframe') }

      elements.map { |element| DESCRIPTIONS.fetch(element.name) { "an unsupported <#{element.name}> element" } }.uniq
    end

    private

    def fragment_for(markdown)
      Nokogiri::HTML5.fragment(MarkdownRenderer.render(markdown))
    end

    def absolutise(element)
      %w[href src].each do |attribute|
        value = element[attribute]
        element[attribute] = "#{base_url}#{value}" if value&.start_with?('/') && !value.start_with?('//')
      end
    end

    def base_url
      Rails.application.routes.url_helpers.root_url.chomp('/')
    end
  end
end
