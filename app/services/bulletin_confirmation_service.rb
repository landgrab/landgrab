# frozen_string_literal: true

# Confirms a draft bulletin: checks it is ready, records a delivery for each member of its audience
# who hasn't unsubscribed, and queues the emails. Confirming is one-way. If anything isn't ready the
# bulletin stays a draft and the reasons are added to its errors.
class BulletinConfirmationService
  class << self
    # @return [Boolean] whether the bulletin was confirmed
    def call(bulletin)
      new(bulletin).call
    end
  end

  def initialize(bulletin)
    @bulletin = bulletin
  end

  def call
    deliveries = nil

    bulletin.with_lock do
      deliveries = confirm if ready?
    end

    return false if deliveries.nil?

    ActiveJob.perform_all_later(deliveries.map { |delivery| BulletinDeliveryJob.new(delivery) })
    true
  end

  private

  attr_reader :bulletin

  def ready?
    if bulletin.confirmed?
      bulletin.errors.add(:base, 'This bulletin has already been confirmed')
      return false
    end
    return false unless bulletin.valid?

    problems = unpublished_post_problems + bulletin.content_problems
    problems << 'Everyone in the audience has unsubscribed, so nobody would receive this bulletin' if recipients.empty?
    problems.each { |problem| bulletin.errors.add(:base, problem) }

    problems.empty?
  end

  def unpublished_post_problems
    bulletin.posts.reject { |post| post.published_at.present? && post.published_at <= Time.zone.now }
            .map { |post| "Post '#{post.title}' is not published yet" }
  end

  def recipients
    @recipients ||= bulletin.audience.where(bulletin_emails: true)
  end

  def confirm
    deliveries = recipients.map { |user| bulletin.deliveries.create!(user:) }
    bulletin.update!(confirmed_at: Time.zone.now)
    deliveries
  end
end
