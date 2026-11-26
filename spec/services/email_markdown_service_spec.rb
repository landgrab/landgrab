# frozen_string_literal: true

RSpec.describe EmailMarkdownService do
  describe '.render' do
    it 'renders the supported basics' do
      html = described_class.render("Hello **bold** and *italic*\n\n- one\n- two\n\n1. first\n\n[a link](https://example.org)")

      expect(html).to include('<strong>bold</strong>', '<em>italic</em>', '<li>one</li>', '<ol>', '<a href="https://example.org">a link</a>')
    end

    it 'keeps images, without the web styling classes' do
      html = described_class.render('![A tree](https://example.org/tree.jpg)')

      expect(html).to include('src="https://example.org/tree.jpg"', 'alt="A tree"')
      expect(html).not_to include('img-fluid')
    end

    it 'makes relative links and images absolute' do
      html = described_class.render("[map](/projects)\n\n![tree](/tree.jpg)")

      expect(html).to include('href="http://example.com/projects"', 'src="http://example.com/tree.jpg"')
    end

    it 'removes scripts and other unsafe markup' do
      html = described_class.render("<script>alert(1)</script>\n\n<a href=\"javascript:alert(1)\" onclick=\"x()\">hi</a>")

      expect(html).not_to include('<script', 'javascript:', 'onclick')
    end

    it 'is empty for blank text' do
      expect(described_class.render(nil)).to eq ''
    end
  end

  describe '.unsupported_elements' do
    it 'accepts the supported basics' do
      markdown = "Hello **bold** *italic*\n\n- one\n- two\n\n[link](https://example.org) ![alt](https://example.org/a.jpg)"

      expect(described_class.unsupported_elements(markdown)).to be_empty
    end

    it 'is empty for blank text' do
      expect(described_class.unsupported_elements(nil)).to be_empty
    end

    {
      'a table' => "| a | b |\n|---|---|\n| 1 | 2 |",
      'code' => "```\nputs 1\n```",
      'a heading' => '## Big news',
      'a quote' => '> wise words',
      'an embedded video or frame' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'an unsupported <video> element' => '<video src="a.mp4"></video>'
    }.each do |description, markdown|
      it "reports #{description}" do
        expect(described_class.unsupported_elements(markdown)).to include(description)
      end
    end

    it 'reports inline code' do
      expect(described_class.unsupported_elements('Run `rake`')).to eq ['code']
    end

    it 'reports each kind once, and does not blame the wrapper around an embed' do
      markdown = "## One\n\n### Two\n\nhttps://youtu.be/dQw4w9WgXcQ"

      expect(described_class.unsupported_elements(markdown)).to contain_exactly('a heading', 'an embedded video or frame')
    end
  end
end
