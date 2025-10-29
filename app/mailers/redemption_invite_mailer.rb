# frozen_string_literal: true

class RedemptionInviteMailer < ApplicationMailer
  helper :posts

  def invite(redemption_invite)
    @redemption_invite = redemption_invite

    raise 'Missing recipient email' if @redemption_invite.recipient_email.nil?

    raise 'Missing token' if @redemption_invite.token.nil?

    mail(
      to: @redemption_invite.recipient_email,
      cc: [
        @redemption_invite.subscription.subscriber.email,
        LandgrabService.email_from_address
      ].compact,
      subject: "#{ENV.fetch('SITE_TITLE', 'LandGrab')} - a gift to you from #{@redemption_invite.subscription.subscriber.display_name}!"
    )
  end
end
