# frozen_string_literal: true

module SubscriptionsHelper
  def render_subscription_price(subscription)
    return nil if subscription.price.nil?

    if subscription.recurring_interval.present?
      "#{subscription.price.format} / #{subscription.recurring_interval}"
    else
      subscription.price.format
    end
  end

  def render_subscription_status(subscription)
    return if subscription.stripe_status.nil?

    content_tag :span,
                subscription.stripe_status.humanize,
                class: "badge bg-#{subscription_class(subscription)}"
  end

  def subscription_class(subscription)
    case subscription.stripe_status
    when 'active'
      'success'
    when 'incomplete', 'incomplete_expired', 'trialing'
      'warning'
    when 'past_due', 'unpaid', 'canceled'
      'danger'
    else
      raise "Unexpected stripe status: #{subscription.stripe_status}"
    end
  end

  def subscription_redemption_text(subscription, current_user)
    if subscription.subscriber == current_user
      msg = "Sponsored by you since #{subscription.created_at.to_date.strftime('%d %B %Y')}"
      if subscription.redeemer.nil?
        "#{msg} (but not yet redeemed)"
      elsif subscription.redeemer != current_user
        "#{msg} (on behalf of #{subscription.redeemer.first_name})"
      else
        msg
      end
    elsif subscription.redeemer == current_user
      "Sponsored on your behalf by #{subscription.subscriber.first_name}"
    else
      raise "Unhandled subscriber/redeemer state for Subscription##{subscription.id}"
    end
  end
end
