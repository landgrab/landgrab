# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/subscription
class SubscriptionMailerPreview < ActionMailer::Preview
  def claim
    subscr = Subscription.new(
      id: 999_999_999,
      claim_hash: SecureRandom.base36,
      claim_email: 'subscriber@example.com'
    )

    SubscriptionMailer.claim(subscr)
  end
end
