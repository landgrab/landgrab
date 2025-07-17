# frozen_string_literal: true

RSpec.describe Admin::PostsController do
  let(:admin) { create(:user, admin: true) }

  describe 'PATCH update with mentioned tiles' do
    let(:post_record) { create(:post, title: 'Original Title', body: 'Original body content') }
    let(:apple_tile) { create(:tile, w3w: 'apple.banana.cherry') }
    let(:grape_tile) { create(:tile, w3w: 'grape.orange.lemon') }
    let(:kiwi_tile) { create(:tile, w3w: 'kiwi.melon.pear') }

    before do
      sign_in(admin, scope: :user)
      # Make sure the tiles exist in the database
      apple_tile
      grape_tile
      kiwi_tile
    end

    context 'when updating a post with w3w mentions' do
      it 'associates newly mentioned tiles with the post' do
        # Update the post with body containing tile mentions
        patch :update, params: {
          id: post_record.hashid,
          post: {
            title: 'Updated Title',
            body: 'Check out these locations: ///apple.banana.cherry and ///grape.orange.lemon'
          }
        }

        # Reload the post to get latest associations
        post_record.reload

        # Check that the update was successful
        expect(response).to redirect_to(admin_post_path(post_record))

        # Check that the post is now associated with the mentioned tiles
        associated_tiles = post_record.associated_tiles
        expect(associated_tiles).to include(apple_tile)
        expect(associated_tiles).to include(grape_tile)
        expect(associated_tiles).not_to include(kiwi_tile)
      end

      it 'only associates tiles when body changes' do
        # First, update the post with a body containing a tile mention
        patch :update, params: {
          id: post_record.hashid,
          post: {
            title: 'First Update',
            body: 'Check out this location: ///apple.banana.cherry'
          }
        }

        post_record.reload
        expect(post_record.associated_tiles).to include(apple_tile)

        # Now update only the title, the associations should remain unchanged
        expect {
          patch :update, params: {
            id: post_record.hashid,
            post: {
              title: 'Second Update - Title Only',
              body: 'Check out this location: ///apple.banana.cherry'
            }
          }
        }.not_to change { post_record.post_associations.count }
      end

      it 'adds new associations without removing existing ones' do
        # Create an initial association
        post_record.post_associations.create(postable: kiwi_tile)

        # Update with new mentions
        patch :update, params: {
          id: post_record.hashid,
          post: {
            body: 'New mentions: ///apple.banana.cherry and ///grape.orange.lemon'
          }
        }

        post_record.reload
        associated_tiles = post_record.associated_tiles

        # All three tiles should now be associated
        expect(associated_tiles).to include(apple_tile)
        expect(associated_tiles).to include(grape_tile)
        expect(associated_tiles).to include(kiwi_tile)
      end

      it 'handles updating a post with no w3w mentions' do
        # First associate a tile
        post_record.post_associations.create(postable: apple_tile)

        # Update with no mentions
        patch :update, params: {
          id: post_record.hashid,
          post: {
            body: 'No mentions here.'
          }
        }

        # The update should succeed
        expect(response).to redirect_to(admin_post_path(post_record))

        # Existing associations should remain
        post_record.reload
        expect(post_record.associated_tiles).to include(apple_tile)
      end

      it 'avoids creating duplicate associations' do
        # Create an initial association
        post_record.post_associations.create(postable: apple_tile)

        # Update with mention to the same tile
        expect {
          patch :update, params: {
            id: post_record.hashid,
            post: {
              body: 'Mentioning again: ///apple.banana.cherry'
            }
          }
        }.not_to change { post_record.post_associations.count }
      end
    end
  end
end
