# frozen_string_literal: true

RSpec.describe Admin::PostsController do
  let(:admin) { create(:user, admin: true) }
  let(:post_params) do
    {
      title: 'New Post With Mentions',
      body: 'Check these locations: ///delta.echo.foxtrot and ///golf.hotel.india',
      publish_immediately: 'true'
    }
  end

  describe 'POST create with mentioned tiles' do
    let(:delta_tile) { create(:tile, w3w: 'delta.echo.foxtrot') }
    let(:golf_tile) { create(:tile, w3w: 'golf.hotel.india') }

    before do
      sign_in(admin, scope: :user)
      delta_tile
      golf_tile
    end

    it 'creates a new post' do
      expect do
        post :create, params: { post: post_params }
      end.to change(Post, :count).by(1)
    end

    it 'associates tiles mentioned in post body' do
      post :create, params: { post: post_params }
      new_post = Post.last
      expect(new_post.associated_tiles).to include(delta_tile, golf_tile)
    end
  end
end
