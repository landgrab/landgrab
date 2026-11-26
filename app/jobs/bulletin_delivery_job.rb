# frozen_string_literal: true

# Sends one bulletin email. It tries once: a failure is recorded on the delivery for an admin to see,
# and never raised, so one bad address can't hold up the rest. Safe to run twice, because it skips
# deliveries already sent.
class BulletinDeliveryJob < ApplicationJob
  queue_as :default

  def perform(delivery)
    delivery.with_lock do
      next unless delivery.pending?

      send_email(delivery)
    end
  end

  private

  def send_email(delivery)
    user = delivery.user
    return record_failure(delivery, 'The user no longer exists') if user.nil?
    return record_failure(delivery, 'The user unsubscribed before this was sent') unless user.bulletin_emails?

    BulletinMailer.with(bulletin: delivery.bulletin, user:).bulletin.deliver_now

    # The address is whatever the user has now, which is where it was sent
    delivery.update!(email: user.email, sent_at: Time.zone.now)
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    record_failure(delivery, "#{e.class}: #{e.message}")
  end

  def record_failure(delivery, message)
    delivery.update!(failed_at: Time.zone.now, error: message)
  end
end
