# frozen_string_literal: true

module Admin
  class PostAssociationsController < ApplicationController
    before_action :check_admin

    before_action :set_post_association, only: %i[destroy]

    def create
      @post_association = PostAssociation.new(post_association_params)
      @post = @post_association.post

      if @post_association.save
        redirect_back fallback_location: admin_post_path(@post),
                      notice: 'Post association was successfully created.'
      else
        redirect_back fallback_location: @post.present? ? admin_post_path(@post) : admin_posts_path,
                      alert: "Failed to associate: #{@post_association.errors.full_messages.to_sentence}"
      end
    end

    def destroy
      @post_association.destroy

      redirect_back fallback_location: admin_post_path(@post_association.post),
                    notice: 'Association was deleted.'
    end

    private

    def set_post_association
      @post_association = PostAssociation.find_by_hashid!(params[:id])
    end

    def post_association_params
      params.expect(post_association: %i[postable_type postable_id post_id]).tap do |tmp|
        tmp[:post_id] = Post.decode_id(tmp[:post_id])
        tmp[:postable_id] =
          case tmp[:postable_type]
          when 'Project'
            Project.decode_id(tmp[:postable_id])
          when 'Plot'
            Plot.decode_id(tmp[:postable_id])
          when 'Team'
            Team.decode_id(tmp[:postable_id])
          when 'Tile'
            if tmp[:postable_id].match?(Tile::W3W_REGEX)
              Tile.find_by!(w3w: tmp[:postable_id]).id
            else
              Tile.decode_id(tmp[:postable_id])
            end
          else
            raise "Unexpected postable_type: #{tmp[:postable_type]}"
          end
      end
    end
  end
end
