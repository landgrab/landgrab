# frozen_string_literal: true

RSpec.describe Admin::PostsController do
  let(:admin) { create(:user, admin: true) }

  describe 'POST create with mentioned tiles' do
    let(:tile1) { create(:tile, w3w: 'delta.echo.foxtrot') }
    let(:tile2) { create(:tile, w3w: 'golf.hotel.india') }

    before do
      sign_in(admin, scope: :user)
      # Make sure the tiles exist in the database
      tile1
      tile2
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
      expect(new_post.associated_tiles).to include(tile1)
      expect(new_post.associated_tiles).to include(tile2)
    end
  end
end
