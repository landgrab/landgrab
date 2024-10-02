# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/../../app/helpers/posts_helper"

RSpec.describe PostsHelper do
  describe '#markdown' do
    it 'renders images with rounded corners' do
      markdown = '![my_alt_text](/my_img.png "my_title")'
      html = helper.markdown(markdown)

      expect(html).to eq %(<p><img src="/my_img.png" title="my_title" alt="my_alt_text" class="rounded img-fluid" /></p>\n)
    end

    %w[
      https://www.youtube.com/watch?v=abc-123
      https://youtube.com/shorts/abc-123
      https://youtu.be/abc-123
    ].each do |yt_link|
      it "renders iframe for YouTube URL #{yt_link}" do
        html = helper.markdown(yt_link)

        expect(html).to include %(<div class="ratio ratio-16x9">)
        expect(html).to include 'src="https://www.youtube.com/embed/abc-123"'
      end
    end
  end
end
