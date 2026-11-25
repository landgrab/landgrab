# frozen_string_literal: true

RSpec.describe AdminHelper do
  describe '#admin_new_button' do
    it 'links to the new form as a primary button' do
      html = Nokogiri::HTML.fragment(helper.admin_new_button(Post))
      link = html.at_css('a')

      expect(link.text).to eq('New Post')
      expect(link['href']).to eq(new_admin_post_path)
      expect(link['class']).to eq('btn btn-primary')
    end

    it 'supports a custom label and query params' do
      project = create(:project)
      html = helper.admin_new_button(Plot, label: 'Create New Plot', params: { project_id: project.hashid })
      link = Nokogiri::HTML.fragment(html).at_css('a')

      expect([link.text, link['href']]).to eq(['Create New Plot', new_admin_plot_path(project_id: project.hashid)])
    end

    it 'supports a small size' do
      link = Nokogiri::HTML.fragment(helper.admin_new_button(Post, small: true)).at_css('a')

      expect(link['class']).to eq('btn btn-primary btn-sm')
    end
  end

  describe '#admin_edit_button' do
    it 'links to the edit form as a secondary button' do
      post = create(:post)
      link = Nokogiri::HTML.fragment(helper.admin_edit_button(post)).at_css('a')

      expect(link.text).to eq('Edit Post')
      expect(link['href']).to eq(edit_admin_post_path(post))
      expect(link['class']).to eq('btn btn-secondary')
    end

    it 'supports a small size' do
      promo_code = create(:promo_code)
      link = Nokogiri::HTML.fragment(helper.admin_edit_button(promo_code, small: true)).at_css('a')

      expect(link.text).to eq('Edit Promo Code')
      expect(link['class']).to eq('btn btn-secondary btn-sm')
    end
  end

  describe '#admin_page_header' do
    it 'renders the title with the given actions alongside' do
      html = Nokogiri::HTML.fragment(
        helper.admin_page_header('Posts') { helper.admin_new_button(Post) }
      )

      expect(html.at_css('h1').text).to eq('Posts')
      expect(html.at_css('div > div a').text).to eq('New Post')
    end
  end
end
