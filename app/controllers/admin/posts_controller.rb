# frozen_string_literal: true

module Admin
  class PostsController < ApplicationController
    before_action :check_admin
    before_action :set_post, only: %i[show edit update bulk_association_edit bulk_association_update]

    has_scope :title
    has_scope :body
    has_scope :preview

    def index
      @posts = apply_scopes(Post).all
      @posts = @posts.where(author_id: User.decode_id(params[:author])) if params[:author].present?
      @posts = @posts.published(%w[1 true].include?(params[:published])) if params[:published].present?

      respond_to do |format|
        format.html do
          @posts = @posts.order(id: :desc).page(params[:page])
          render :index
        end
        format.csv { render_csv('posts') }
      end
    end

    def show; end

    def new
      @post = Post.new
    end

    def edit
      @post_association = @post.post_associations.new
    end

    def create
      @post = Post.new(post_params_for_create)
      @post.author = current_user

      if @post.save
        @post.update!(published_at: @post.created_at) if @post.publish_immediately == 'true'
        redirect_to admin_post_path(@post), notice: 'Post was successfully created.'
      else
        render :new
      end
    end

    def update
      if @post.update(post_params_for_update)
        redirect_to admin_post_path(@post), notice: 'Post was successfully updated.'
      else
        render :edit
      end
    end

    def bulk_association_edit
      @plot = Plot.find_by_hashid!(params[:plot]) if params[:plot].present?
    end

    def bulk_association_update
      w3w_list = params[:w3w_list].split(',').map(&:squish)
      # TODO: Is there a Rails way to update (add/remove) these in a neater/performant way?
      required_tiles = Tile.where(w3w: w3w_list)
      existing_tiles = @post.associated_tiles

      tiles_to_remove = existing_tiles - required_tiles
      @post.post_associations.where(postable_type: 'Tile', postable_id: tiles_to_remove.map(&:id)).destroy_all

      tiles_to_add = required_tiles - existing_tiles
      tiles_to_add.each do |tile|
        @post.post_associations.create(postable: tile)
      end

      redirect_to admin_post_path(@post),
                  flash: { success: "Associations updated; added #{view_context.pluralize(tiles_to_add.size, 'tile')}, removed #{tiles_to_remove.size}." }
    end

    private

    def set_post
      @post = Post.find_by_hashid!(params[:id])
    end

    def post_params_for_create
      params.expect(post: %i[title preview body hero_image publish_immediately])
    end

    def post_params_for_update
      params.expect(post: %i[title preview body hero_image published_at])
    end
  end
end
