# frozen_string_literal: true

RSpec.describe Admin::PostsController do
  render_views

  let(:admin) { create(:user, admin: true) }
  let(:post_record) { create(:post) }
  let(:plot) { create(:plot) }
  let(:associated_tile) { create(:tile, plot: plot, w3w: 'apple.banana.cherry') }
  let(:unassociated_tile) { create(:tile, plot: plot, w3w: 'grape.orange.lemon') }
  let(:other_plot) do
    create(:plot, title: 'Other Plot',
                  polygon: 'POLYGON ((-1.02018 52.51576, -1.02002 52.51591, -1.01981 52.51558, -1.02018 52.51576))')
  end
  let(:tile_in_other_plot) { create(:tile, plot: other_plot, w3w: 'kiwi.melon.pear') }

  before do
    sign_in(admin, scope: :user)
    create(:post_association, post: post_record, postable: associated_tile)
    create(:post_association, post: post_record, postable: tile_in_other_plot)
    unassociated_tile
  end

  describe 'GET bulk_association_edit' do
    subject(:do_get) { get :bulk_association_edit, params: { id: post_record.hashid, plot: plot.hashid } }

    it 'pre-selects every tile already associated, including those outside the plot' do
      do_get

      expect(response.body).to include("w3wList.add('apple.banana.cherry')", "w3wList.add('kiwi.melon.pear')")
      expect(response.body).not_to include("w3wList.add('grape.orange.lemon')")
    end

    it 'links back to the post being associated' do
      do_get

      link = response.parsed_body.xpath("//a[normalize-space()='#{post_record.title}']").first
      expect(link['href']).to eq admin_post_path(post_record)
    end

    it 'marks the associated tiles as selected on the map' do
      do_get

      expect(response.body).to include('tile.properties.focussed = w3wList.has(tile.properties.w3w)')
    end
  end
end
