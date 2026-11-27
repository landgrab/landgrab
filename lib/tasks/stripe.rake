# frozen_string_literal: true

namespace :stripe do
  desc 'Create or repair the Stripe webhook endpoint (WEBHOOK_BASE_URL=https://example.com)'
  task setup_webhook: :environment do
    base_url = ENV.fetch('WEBHOOK_BASE_URL') { abort 'Set WEBHOOK_BASE_URL, e.g. https://example.com' }

    service = StripeWebhookSetupService.new(base_url)
    result = service.call

    puts "#{result.created ? 'Created' : 'Updated'} Stripe webhook endpoint #{result.endpoint.id} for #{service.url}"
    puts "Listening for: #{StripeWebhookSetupService::ENABLED_EVENTS.join(', ')}"

    if result.created
      puts 'Set this on the app (it is only shown once):'
      puts "STRIPE_WEBHOOK_SIGNING_SECRET=#{result.secret}"
    else
      puts 'Signing secret unchanged: reveal it in the Stripe dashboard if needed.'
    end
  end
end
