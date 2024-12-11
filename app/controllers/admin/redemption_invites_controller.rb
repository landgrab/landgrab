# frozen_string_literal: true

module Admin
  class RedemptionInvitesController < ApplicationController
    before_action :check_admin

    def index
      @redemption_invites = RedemptionInvite.all.includes(subscription: %i[subscriber redeemer])

      respond_to do |format|
        format.html do
          @redemption_invites = @redemption_invites.order(id: :desc).page(params[:page])
          render :index
        end
        format.csv { render_csv('redemption_invites') }
      end
    end

    def create
      @redemption_invite = RedemptionInvite.new(redemption_invite_params)
      if @redemption_invite.save
        redirect_to admin_subscription_path(@redemption_invite.subscription), notice: 'Invite was successfully created.'
      else
        redirect_to admin_subscription_path(@redemption_invite.subscription),
                    alert: "Failed: #{@redemption_invite.errors.full_messages.join(', ')}"
      end
    end

    private

    def redemption_invite_params
      params.require(:redemption_invite).permit(:subscription_id, :recipient_name, :recipient_email).tap do |tmp|
        tmp[:subscription_id] = Subscription.decode_id(tmp[:subscription_id])
      end
    end
  end
end
