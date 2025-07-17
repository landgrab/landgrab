# frozen_string_literal: true

RSpec.describe Admin::PostsController do
  let(:admin) { create(:user, admin: true) }

  describe 'POST create with mentioned tiles' do
    let(:delta_tile) { create(:tile, w3w: 'delta.echo.foxtrot') }
    let(:golf_tile) { create(:tile, w3w: 'golf.hotel.india') }

    before do
      sign_in(admin, scope: :user)
      # Make sure the tiles exist in the database
      delta_tile
      golf_tile
    end

    it 'associates mentioned tiles when creating a new post' do
      expect {
        post :create, params: {
          post: {
            title: 'New Post With Mentions',
            body: 'Check these locations: ///delta.echo.foxtrot and ///golf.hotel.india',
            publish_immediately: 'true'
          }
        }
      }.to change(Post, :count).by(1)

      new_post = Post.last
      expect(new_post.associated_tiles).to include(delta_tile)
      expect(new_post.associated_tiles).to include(golf_tile)
    end
  end
end
