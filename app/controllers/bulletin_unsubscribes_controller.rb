# frozen_string_literal: true

# Unsubscribes a user from bulletin emails using the signed token in an email's unsubscribe link,
# so no login is needed. Showing the page (GET) changes nothing, because email scanners prefetch
# links; the POST does the unsubscribing. Mail clients' one-click requests go to
# BulletinOneClickUnsubscribesController instead.
class BulletinUnsubscribesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :store_location

  before_action :set_user

  def show; end

  def create
    @user.update!(bulletin_emails: false)
  end

  private

  def set_user
    @user = User.find_by_token_for(:bulletin_unsubscribe, params[:token])

    render :invalid, status: :not_found if @user.nil?
  end
end
