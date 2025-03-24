# frozen_string_literal: true

RSpec.describe PostsController do
  render_views

  describe 'GET posts#show' do
    subject(:do_get) do
      get :show, params: { id: post.hashid }
    end

    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, subscriber: user) }
    let(:project) { create(:project) }
    let(:tile) { create(:tile) }
    let(:post) { create(:post, title: 'post title', body: 'post body', preview: 'post preview') }

    before do
      sign_in(user)
    end

    context 'when logged out' do
      before do
        sign_out(user)
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows login link' do
        do_get

        expect(response.body).to include(new_user_session_path)
      end

      it 'shows the post preview anyway' do
        do_get

        expect(response.body).to include(post.preview)
      end

      it 'does not show the post body' do
        do_get

        expect(response.body).not_to include(post.body)
      end
    end

    context 'with no associated places' do
      it 'shows that nothing is associated' do
        do_get

        expect(response.body).to include("post isn't associated with any places")
      end
    end

    context 'with an associated tile but no subscription' do
      before do
        create(:post_association, post:, postable: tile)
      end

      it 'shows the post preview' do
        do_get

        expect(response.body).to include(post.preview)
      end

      it 'mentions the tile' do
        do_get

        expect(response.body).to include(tile.w3w)
      end
    end

    context 'with an associated tile subscribed by current user' do
      before do
        create(:post_association, post:, postable: tile)
        create(:subscription, subscriber: user, tile:)
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'shows the full post body' do
        do_get

        expect(response.body).to include(post.body)
      end

      it 'creates a post view and renders a link to share access' do
        expect { do_get }.to change(PostView, :count).by(1)

        pv = PostView.last
        expect(response.body).to include(access_post_url(post, access_key: pv.shared_access_key))
      end

      it 'mentions the tile' do
        do_get

        expect(response.body).to include(tile.w3w)
      end
    end
  end
end
