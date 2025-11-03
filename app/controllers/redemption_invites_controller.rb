# frozen_string_literal: true

class RedemptionInvitesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[redeem]
  before_action :set_redemption_invite, only: %i[update redeem]

  def create
    @redemption_invite = RedemptionInvite.new(redemption_invite_params_for_create)

    if @redemption_invite.invalid?
      redirect_back fallback_location: subscriptions_path,
                    flash: { error: @redemption_invite.errors.full_messages.join(', ') }
      return
    end

    validate_user_ownership!

    @redemption_invite.save!

    queue_redemption_invite_email if @redemption_invite.recipient_email.present?

    redirect_to subscription_path(@redemption_invite.subscription),
                notice: 'Invite successfully created.'
  end

  def update
    validate_user_ownership!

    @redemption_invite.assign_attributes(redemption_invite_params_for_update)

    if attempting_frequent_email_change?
      return redirect_back fallback_location: subscription_path(@redemption_invite.subscription),
                           flash: { error: 'Please wait at least 2 hours before sending to a new email address. You can set it as blank for now if needed.' }
    end

    if @redemption_invite.save
      notice_message = reset_token_and_send_email_if_changed

      redirect_to subscription_path(@redemption_invite.subscription),
                  notice: notice_message
    else
      redirect_back fallback_location: subscription_path(@redemption_invite.subscription),
                    flash: { error: @redemption_invite.errors.full_messages.join(', ') }
    end
  end

  def redeem
    valid_token = @redemption_invite.verify_token(params[:token])
    unless user_signed_in?
      # Only pre-fill registration form from a valid invite
      prefill_params = { first_name: @redemption_invite.recipient_name, email: @redemption_invite.recipient_email } if valid_token
      return redirect_to new_user_registration_path(prefill_params),
                         flash: { notice: 'Please register in order to redeem an invite/gift' }
    end

    @subscription = @redemption_invite.subscription

    unless valid_token
      return redirect_to support_path,
                         flash: { danger: "That link doesn't look quite right; please contact us." }
    end

    if @subscription.redeemed?
      return redirect_to @subscription, flash: { notice: 'This subscription is already linked to your account' } if @subscription.redeemed_by?(current_user)

      return redirect_to support_path, flash: { danger: 'Oh! This subscription is already connected to a different account. Have you got two accounts? Please reach out to us and we can help.' }
    end

    return redirect_to @subscription, flash: { notice: 'This link is for sharing, not for clicking yourself!' } if @subscription.subscribed_by?(current_user)

    log_event_mixpanel('Redemption Invite: Redeem')

    @subscription.update!(redeemer: current_user)

    redirect_to @subscription, flash: { notice: "Great; you've redeemed this subscription!" }
  end

  private

  def redemption_invite_params_for_update
    params.expect(redemption_invite: %i[recipient_name recipient_email])
  end

  def redemption_invite_params_for_create
    params.expect(redemption_invite: %i[subscription_id recipient_name recipient_email]).tap do |tmp|
      tmp[:subscription_id] = Subscription.decode_id(tmp[:subscription_id])
    end
  end

  def set_redemption_invite
    @redemption_invite = RedemptionInvite.find_by_hashid!(params[:id])
  end

  def queue_redemption_invite_email
    RedemptionInviteMailer.invite(@redemption_invite).deliver_later
  end

  def validate_user_ownership!
    return if @redemption_invite.subscription&.subscribed_by?(current_user)

    raise "User##{current_user.hashid} does not own Subscription##{@redemption_invite.subscription.hashid}"
  end

  def reset_token_and_send_email_if_changed
    notice_message = 'Invitation updated'
    return "#{notice_message} (but no email sent as email was not updated)." unless @redemption_invite.previous_changes.key?(:recipient_email)

    notice_message += ', links reset'
    @redemption_invite.reset_token
    @redemption_invite.save!

    return "#{notice_message} (but no email sent as email was wiped)." if @redemption_invite.recipient_email.blank?

    queue_redemption_invite_email
    "#{notice_message} and new invitation email sent."
  end

  def attempting_frequent_email_change?
    # It's fine to update once after initial creation
    return false if @redemption_invite.created_at == @redemption_invite.updated_at

    # It's fine to update again after some time has passed
    return false if @redemption_invite.updated_at < 2.hours.ago

    # It's also fine to update if the email is being wiped (or was already blank)
    return false if @redemption_invite.recipient_email.blank?

    true
  end
end
