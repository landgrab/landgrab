# frozen_string_literal: true

# Handles the one-click unsubscribe request (RFC 8058) that mail clients send when someone presses
# their built-in unsubscribe button. It has no session or cookies, so there is nothing for a forged
# cross-site request to ride on: the signed token in the URL is the only credential.
class BulletinOneClickUnsubscribesController < ActionController::API
  def create
    user = User.find_by_token_for(:bulletin_unsubscribe, params[:token])
    return head :not_found if user.nil?

    user.update!(bulletin_emails: false)
    head :ok
  end
end
