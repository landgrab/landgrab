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

  describe 'POST create with associations' do
    let(:team) { create(:team) }
    let(:project) { create(:project) }
    let(:tile) { create(:tile, w3w: 'apple.banana.cherry') }

    before { sign_in(admin, scope: :user) }

    it 'associates the chosen postables' do
      post :create, params: { post: { title: 'T', body: 'B', team_ids: ['', team.hashid],
                                      project_ids: [project.hashid], tile_w3w_list: tile.w3w } }

      expect(Post.last.post_associations.map(&:postable)).to contain_exactly(team, project, tile)
    end

    it 'creates the post without associations' do
      expect { post :create, params: { post: { title: 'T', body: 'B' } } }.to change(Post, :count).by(1)
    end
  end

  describe 'POST create with unknown tile addresses' do
    render_views

    let(:known_tile) { create(:tile, w3w: 'apple.banana.cherry') }

    before { sign_in(admin, scope: :user) }

    def create_with_tiles(list)
      post :create, params: { post: { title: 'T', body: 'B', tile_w3w_list: list } }
    end

    it 'does not create the post' do
      expect { create_with_tiles("#{known_tile.w3w}, no.such.place") }.not_to change(Post, :count)
    end

    it 'names every unknown address in the error' do
      create_with_tiles("#{known_tile.w3w}, no.such.place, ///also.not.here")

      expect(response.body).to include('Unknown What3Words addresses in tiles: no.such.place, also.not.here')
    end

    it 'keeps the submitted tiles in the field' do
      create_with_tiles('no.such.place')

      expect(response.body).to include('no.such.place</textarea>')
    end
  end

  describe 'GET new with a preset postable' do
    render_views

    before { sign_in(admin, scope: :user) }

    it 'preselects the team' do
      team = create(:team)
      get :new, params: { postable_type: 'Team', postable_id: team.hashid }

      expect(response.body).to match(/<option selected="selected" value="#{team.hashid}"/)
    end

    it 'prefills the tile address' do
      tile = create(:tile, w3w: 'apple.banana.cherry')
      get :new, params: { postable_type: 'Tile', postable_id: tile.hashid }

      expect(response.body).to include('apple.banana.cherry</textarea>')
    end

    it 'ignores an unknown postable type' do
      get :new, params: { postable_type: 'User', postable_id: admin.hashid }

      expect(response).to be_successful
    end
  end
end
