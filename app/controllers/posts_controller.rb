# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :set_post, only: %i[access show]
  skip_before_action :authenticate_user!, only: %i[access show]

  def show
    @viewable = user_signed_in? && @post.viewable_by?(current_user)

    @latest_post_view = latest_post_view if @viewable

    log_event_mixpanel('Posts: Show', { authed: user_signed_in?, viewable: @viewable })
  end

  def access
    if params[:access_key].present?
      @sharer = @post.post_views
                     .find_by(shared_access_key: params[:access_key])
                     &.user
    end

    if @sharer.nil?
      redirect_to post_path(@post), flash: { danger: 'There was something wrong with that access link.' }
      return
    end

    @viewable = true

    log_event_mixpanel('Posts: Access', { authed: user_signed_in?, viewable: @viewable })

    render :show
  end

  private

  def latest_post_view
    @post.post_views
         .where(user: current_user)
         .where('created_at > ?', 1.hour.ago)
         .first ||
      @post.post_views
           .create!(user: current_user, shared_access_key: SecureRandom.hex)
  end

  def set_post
    @post = Post.find_by_hashid!(params[:id])
  end
end
