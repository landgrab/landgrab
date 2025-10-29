# frozen_string_literal: true

RSpec.describe RedemptionInvitesController do
  describe 'POST redemption_invites#create' do
    subject(:do_post) do
      post :create, params: { redemption_invite: redemption_invite_params }
    end

    let(:redemption_invite_params) do
      {
        subscription_id: subscription.hashid,
        recipient_name: 'Mr Recipient',
        recipient_email: 'recipient@example.com'
      }
    end

    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, subscriber: user) }

    let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    before do
      sign_in(user)
    end

    it 'creates a redemption invite with correct data' do
      expect { do_post }.to change(RedemptionInvite, :count).by(1)

      ri = RedemptionInvite.last
      expect(ri.subscription_id).to eq subscription.id
      expect(ri.recipient_name).to eq 'Mr Recipient'
      expect(ri.recipient_email).to eq 'recipient@example.com'
    end

    it 'redirects to the subscription' do
      do_post

      expect(response).to redirect_to(subscription_path(subscription))
    end

    it 'sends an email' do
      allow(RedemptionInviteMailer).to receive(:invite).and_return(mailer_double)

      do_post

      expect(RedemptionInviteMailer).to have_received(:invite)
    end

    context 'when logged out' do
      before do
        sign_out(user)
      end

      it 'redirects to login' do
        do_post

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
