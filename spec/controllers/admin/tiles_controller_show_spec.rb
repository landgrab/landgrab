# frozen_string_literal: true

RSpec.describe Admin::TilesController do
  render_views

  let(:admin) { create(:user, admin: true) }
  let(:tile) { create(:tile) }

  before { sign_in(admin, scope: :user) }

  describe 'GET show' do
    it 'links to a new post about the tile' do
      get :show, params: { id: tile.hashid }

      link = response.parsed_body.xpath("//a[normalize-space()='Create a post about this tile']").first
      expect(link['href']).to eq new_admin_post_path(postable_type: 'Tile', postable_id: tile.hashid)
    end
  end
end
