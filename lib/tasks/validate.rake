# frozen_string_literal: true

namespace :validate do
  task user_stripe_customer_ids: :environment do
    checked_stripe_ids = []
    puts 'Checking all local users are matched in Stripe...'
    User.where.not(stripe_customer_id: nil).find_each do |user|
      checked_stripe_ids << user.stripe_customer_id
      # puts "Checking User##{user.id} (#{user.stripe_customer_id})..."
      customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      puts "User##{user.hashid} name mismatch: local '#{user.full_name}' vs stripe '#{customer.name || 'NOT PROVIDED'}'" unless user.full_name.downcase == customer.name&.downcase&.squish
      puts "User##{user.hashid} email mismatch: local '#{user.email}' vs stripe '#{customer.email}'" unless user.email == customer.email.downcase
    rescue Stripe::InvalidRequestError
      puts "User##{user.hashid} NOT FOUND in Stripe (#{user.stripe_customer_id})"
    end

    puts 'Checking all Stripe users are matched locally...'
    Stripe::Customer.list.auto_paging_each do |customer|
      next if customer.respond_to?(:deleted) && customer.deleted # skip deleted customers
      next if checked_stripe_ids.include?(customer.id) # avoid redundant checks

      user_by_email = User.find_by(email: customer.email.downcase)
      if user_by_email.present?
        puts "StripeCustomer##{customer.id} NOT LINKED but found matching user by email: User##{user_by_email.hashid} (#{user_by_email.email} / #{user_by_email.stripe_customer_id || 'No Stripe ID'})"
      else
        puts "StripeCustomer##{customer.id} (#{customer.name} / #{customer.email}) NOT FOUND locally (even by email)"
      end
    end

    puts 'Checks complete!'
  end
end
