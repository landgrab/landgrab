# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/subscription
class RedemptionInviteMailerPreview < ActionMailer::Preview
  def invite
    redemption_invite = RedemptionInvite.new(
      id: 999_999_999,
      token: SecureRandom.base36,
      recipient_name: 'Dwayne',
      recipient_email: 'recipient@example.com',
      subscription: Subscription.new(
        id: 999_999_998,
        subscriber: User.new(first_name: 'Galahad', email: 'subscriber@example.com'),
        project: Project.first
      )
    )

    RedemptionInviteMailer.invite(redemption_invite)
  end
end
