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

    def edit; end

    def create
      @post = Post.new(post_params_for_create)
      @post.author = current_user

      if @post.save
        sync_associations
        @post.associate_mentioned_tiles
        @post.update!(published_at: @post.created_at) if @post.publish_immediately == 'true'
        redirect_to admin_post_path(@post), notice: 'Post was successfully created.'
      else
        render :new
      end
    end

    def update
      if @post.update(post_params_for_update)
        sync_associations
        @post.associate_mentioned_tiles if @post.saved_change_to_attribute?(:body)
        redirect_to admin_post_path(@post), notice: 'Post was successfully updated.'
      else
        render :edit
      end
    end

    def bulk_association_edit
      @plot = Plot.find_by_hashid!(params[:plot]) if params[:plot].present?
    end

    def bulk_association_update
      w3w_list = params.expect(:w3w_list)
      unknown = PostAssociationSyncService.unknown_w3w_addresses(w3w_list)
      if unknown.any?
        return redirect_to bulk_association_edit_admin_post_path(@post, plot: params[:plot].presence),
                           flash: { error: PostAssociationSyncService.unknown_w3w_message(unknown) }
      end

      PostAssociationSyncService.call(@post, tile_w3w_list: w3w_list)

      redirect_to admin_post_path(@post), flash: { success: 'Associations updated.' }
    end

    helper_method :selected_associations

    private

    def selected_associations
      @selected_associations ||= SelectedPostAssociationsService.call(
        post: @post,
        submitted: params[:post],
        preset_type: params[:postable_type],
        preset_id: params[:postable_id]
      )
    end

    def sync_associations
      PostAssociationSyncService.call(
        @post,
        **params.fetch(:post, {}).permit(:tile_w3w_list, team_ids: [], project_ids: [], plot_ids: []).to_h.symbolize_keys
      )
    end

    def set_post
      @post = Post.find_by_hashid!(params[:id])
    end

    def post_params_for_create
      params.expect(post: [:title, :preview, :body, :hero_image, :publish_immediately, :tile_w3w_list, { images: [] }])
    end

    def post_params_for_update
      params.expect(post: [:title, :preview, :body, :hero_image, :published_at, :tile_w3w_list, { images: [] }])
    end
  end
end
