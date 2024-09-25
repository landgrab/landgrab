# frozen_string_literal: true

namespace :subscription do
  desc 'Refresh Stripe statuses'
  task refresh_stripe_statuses: :environment do
    Subscription.find_each do |s|
      next if s.stripe_id.nil? || s.stripe_id.start_with?('sub_fake')

      StripeSubscriptionRefreshJob.perform_later(s)
    end
  end

  desc 'Create fake subscription for testing'
  task fake_subscription: :environment do
    n = ENV.fetch('COUNT', '3').to_i
    Tile.available.sample(n).each do |tile|
      fake_id = Array.new(8) { rand(0..9) }.join
      Subscription.create!(
        stripe_id: "sub_fake#{fake_id}",
        stripe_status: :trialing,
        tile:
      )
    end
  end

  desc 'Create externally paid subscriptions'
  task create_external: :environment do
    n = ENV.fetch('COUNT', '3').to_i
    n.times do
      fake_id = Array.new(8) { rand(0..9) }.join
      Subscription.create!(
        stripe_id: "#{Subscription::EXTERNALLY_PAID_PREFIX}#{fake_id}",
        stripe_status: :active,
        claim_hash: SecureRandom.base36
      )
    end
  end

  desc 'Validate Stripe Customer Ownership'
  task validate_stripe_customer_ownership: :environment do
    Subscription.where.not(stripe_id: nil).joins(:user).find_each do |subscr|
      next if subscr.stripe_status_canceled?

      stripe_sub = Stripe::Subscription.retrieve(subscr.stripe_id).to_hash
      customer_id = stripe_sub.fetch(:customer)

      next if customer_id == subscr.subscriber.stripe_customer_id

      puts "Subscription #{subscr.hashid} (stripe:#{subscr.stripe_id}) has mismatched customer_id: #{customer_id}"
      puts "User.find_by_hashid!('#{subscr.subscriber.hashid}').update!(stripe_customer_id: '#{customer_id}')"
    end; nil
  end
end
