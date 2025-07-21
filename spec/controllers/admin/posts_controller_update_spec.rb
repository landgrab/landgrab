# frozen_string_literal: true

RSpec.describe Admin::PostsController do
  let(:admin) { create(:user, admin: true) }

  describe 'PATCH update with mentioned tiles' do
    let(:post_record) { create(:post, title: 'Original Title', body: 'Original body content') }
    let(:apple_tile) { create(:tile, w3w: 'apple.banana.cherry') }
    let(:grape_tile) { create(:tile, w3w: 'grape.orange.lemon') }
    let(:kiwi_tile) { create(:tile, w3w: 'kiwi.melon.pear') }
    let(:update_params) do
      {
        id: post_record.hashid,
        post: {
          body: 'Check out these locations: ///apple.banana.cherry and ///grape.orange.lemon'
        }
      }
    end
    let(:title_only_params) do
      {
        id: post_record.hashid,
        post: { title: 'Title Only Update' }
      }
    end
    let(:no_mentions_params) do
      {
        id: post_record.hashid,
        post: { body: 'No mentions here.' }
      }
    end
    let(:duplicate_mention_params) do
      {
        id: post_record.hashid,
        post: { body: 'Mentioning again: ///apple.banana.cherry' }
      }
    end

    before do
      sign_in(admin, scope: :user)
      apple_tile
      grape_tile
      kiwi_tile
    end

    def update_post(params = update_params)
      patch :update, params: params
      post_record.reload
    end

    def associate_tile(tile)
      post_record.post_associations.create(postable: tile)
    end

    context 'when updating a post with w3w mentions' do
      it 'updates the post successfully' do
        patch :update, params: update_params
        expect(response).to redirect_to(admin_post_path(post_record))
      end

      it 'associates mentioned tiles with the post' do
        update_post
        expect(post_record.associated_tiles).to include(apple_tile, grape_tile)
      end

      it 'does not associate unmentioned tiles' do
        update_post
        expect(post_record.associated_tiles).not_to include(kiwi_tile)
      end

      it 'only associates tiles when body changes' do
        update_post
        initial_count = post_record.post_associations.count

        update_post(title_only_params)
        expect(post_record.post_associations.count).to eq(initial_count)
      end

      it 'preserves existing associations' do
        associate_tile(kiwi_tile)
        update_post
        expect(post_record.associated_tiles).to include(kiwi_tile)
      end

      it 'adds newly mentioned tiles to existing ones' do
        associate_tile(kiwi_tile)
        update_post
        expect(post_record.associated_tiles).to include(apple_tile, grape_tile, kiwi_tile)
      end

      it 'preserves associations when updating without mentions' do
        associate_tile(apple_tile)
        update_post(no_mentions_params)
        expect(post_record.associated_tiles).to include(apple_tile)
      end

      it 'avoids creating duplicate associations' do
        associate_tile(apple_tile)
        initial_count = post_record.post_associations.count
        update_post(duplicate_mention_params)
        expect(post_record.post_associations.count).to eq(initial_count)
      end
    end
  end
end
