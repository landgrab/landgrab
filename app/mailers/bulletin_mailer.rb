# frozen_string_literal: true

class BulletinMailer < ApplicationMailer
  helper :email

  layout 'bulletin_mailer'

  # BulletinMailer.with(bulletin:, user:).bulletin
  def bulletin
    @bulletin = params.fetch(:bulletin)
    @user = params.fetch(:user)

    problems = @bulletin.content_problems
    raise ArgumentError, "Bulletin has content unsuitable for email: #{problems.join(' ')}" if problems.any?

    token = @user.generate_token_for(:bulletin_unsubscribe)
    @unsubscribe_url = bulletin_unsubscribe_url(token)

    # Lets mail clients offer their own unsubscribe button (RFC 8058)
    headers['List-Unsubscribe'] = "<#{bulletin_one_click_unsubscribe_url(token)}>"
    headers['List-Unsubscribe-Post'] = 'List-Unsubscribe=One-Click'

    mail(to: @user.email, subject: @bulletin.subject)
  end
end
