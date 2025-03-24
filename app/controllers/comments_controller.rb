# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_comment, only: %i[update destroy]

  def create
    @comment = current_user.comments_authored.create!(comment_params)

    redirect_to post_path(@comment.post),
                notice: 'Comment was successfully created.'
  end

  def update
    @comment.update!(comment_params)

    redirect_to post_path(@comment.post), notice: 'Comment was updated.'
  end

  def destroy
    @comment.destroy

    redirect_to post_path(@comment.post), notice: 'Comment was deleted.'
  end

  private

  def set_comment
    @comment = current_user.comments_authored.find_by_hashid(params[:id])
  end

  def comment_params
    params.expect(comment: [:post_id, :text, :public]).tap do |tmp|
      tmp[:post_id] = Post.decode_id(tmp[:post_id])
    end
  end
end
