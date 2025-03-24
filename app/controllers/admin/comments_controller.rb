# frozen_string_literal: true

module Admin
  class CommentsController < ApplicationController
    before_action :check_admin
    before_action :set_comment, only: %i[show]

    def index
      @post = Post.find_by_hashid!(params[:post]) if params[:post].present?
      @comments = @post.present? ? @post.comments : Comment.includes(:post)
      @user = User.find_by_hashid!(params[:author]) if params[:author].present?
      @comments = @user.present? ? @comments.where(author: @user) : @comments.includes(:author)
      @comments = @comments.order(id: :desc).page(params[:page])
    end

    def show; end

    private

    def set_comment
      @comment = Comment.find_by_hashid!(params[:id])
    end

    def comment_params
      params.expect(comment: %i[text public])
    end
  end
end
