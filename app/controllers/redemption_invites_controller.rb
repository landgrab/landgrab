# frozen_string_literal: true

class RedemptionInvitesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[redeem]

  def create
    @redemption_invite = RedemptionInvite.new(redemption_invite_params)

    if @redemption_invite.invalid?
      redirect_back fallback_location: subscriptions_path,
                    flash: { error: @redemption_invite.errors.full_messages.join(', ') }
      return
    end

    raise "User##{current_user.hashid} does not own Subscription##{@redemption_invite.subscription.hashid}" unless @redemption_invite.subscription&.subscribed_by?(current_user)

    @redemption_invite.save!

    redirect_to subscription_path(@redemption_invite.subscription),
                notice: 'Invite successfully created.'
  end

  def redeem
    @redemption_invite = RedemptionInvite.find_by_hashid!(params[:id])
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

  def redemption_invite_params
    params.expect(redemption_invite: [:subscription_id, :recipient_name, :recipient_email]).tap do |tmp|
      tmp[:subscription_id] = Subscription.decode_id(tmp[:subscription_id])
    end
  end
end
