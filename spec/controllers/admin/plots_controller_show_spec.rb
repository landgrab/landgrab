# frozen_string_literal: true

RSpec.describe Admin::PlotsController do
  render_views

  let(:admin) { create(:user, admin: true) }
  let(:plot) { create(:plot) }

  before { sign_in(admin, scope: :user) }

  describe 'GET show' do
    it 'links to a new post about the plot' do
      get :show, params: { id: plot.hashid }

      link = response.parsed_body.xpath("//a[normalize-space()='Create a post about this plot']").first
      expect(link['href']).to eq new_admin_post_path(postable_type: 'Plot', postable_id: plot.hashid)
    end
  end
end
