# frozen_string_literal: true

RSpec.describe RedemptionInvitesController do
  describe 'PATCH redemption_invites#update' do
    subject(:do_patch) do
      patch :update, params: { id: redemption_invite.hashid, redemption_invite: update_params }
    end

    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, subscriber: user) }
    let(:redemption_invite) { create(:redemption_invite, subscription: subscription, recipient_name: 'Original Name', recipient_email: 'original@example.com', token: 'original_token_123') }

    let(:update_params) do
      {
        recipient_name: 'Updated Name',
        recipient_email: 'updated@example.com'
      }
    end

    let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    before do
      sign_in(user)
    end

    it 'updates the redemption invite attributes' do
      do_patch

      redemption_invite.reload
      expect(redemption_invite.recipient_name).to eq('Updated Name')
      expect(redemption_invite.recipient_email).to eq('updated@example.com')
    end

    it 'redirects to the subscription page with success notice' do
      do_patch

      expect(response).to redirect_to(subscription_path(subscription))
    end

    context 'when recipient_email is changed' do
      it 'resets the token' do
        expect { do_patch }.to change { redemption_invite.reload.token }.from('original_token_123')
      end

      it 'queues a redemption invite email' do
        allow(RedemptionInviteMailer).to receive(:invite).with(redemption_invite).and_return(mailer_double)

        do_patch

        expect(RedemptionInviteMailer).to have_received(:invite).with(redemption_invite)
      end

      it 'shows success notice with email notification' do
        allow(RedemptionInviteMailer).to receive(:invite).and_return(mailer_double)

        do_patch

        expect(flash[:notice]).to eq('Invitation updated, links reset and new invitation email sent.')
      end

      it 'rejects a change made too quickly' do
        redemption_invite.update!(recipient_email: 'other-changed-email@example.com')

        do_patch

        expect(response).to have_http_status(:redirect)
        expect(flash[:error]).to be_present
        expect(flash[:error]).to include('Please wait')
      end
    end

    context 'when recipient_email is changed to blank' do
      let(:update_params) do
        {
          recipient_name: 'Updated Name',
          recipient_email: ''
        }
      end

      it 'resets the token' do
        original_token = redemption_invite.token

        expect { do_patch }.to change { redemption_invite.reload.token }.from(original_token)
      end

      it 'does not send an email' do
        allow(RedemptionInviteMailer).to receive(:invite)

        do_patch

        expect(RedemptionInviteMailer).not_to have_received(:invite)
      end

      it 'shows success notice without email notification' do
        do_patch

        expect(flash[:notice]).to eq('Invitation updated, links reset (but no email sent as email was wiped).')
      end
    end

    context 'when recipient_email is not changed' do
      let(:update_params) do
        {
          recipient_name: 'Updated Name',
          recipient_email: 'original@example.com' # Same as original
        }
      end

      it 'does not reset the token' do
        original_token = redemption_invite.token

        do_patch

        expect(redemption_invite.reload.token).to eq(original_token)
      end

      it 'does not queue email' do
        allow(RedemptionInviteMailer).to receive(:invite)

        do_patch

        expect(RedemptionInviteMailer).not_to have_received(:invite)
      end

      it 'shows success notice without email notification' do
        do_patch

        expect(flash[:notice]).to eq('Invitation updated (but no email sent as email was not updated).')
      end
    end

    context 'when only recipient_name is updated' do
      let(:update_params) do
        {
          recipient_name: 'Updated Name Only'
        }
      end

      it 'updates only the name' do
        do_patch

        redemption_invite.reload
        expect(redemption_invite.recipient_name).to eq('Updated Name Only')
        expect(redemption_invite.recipient_email).to eq('original@example.com')
      end

      it 'does not reset token or send email' do
        original_token = redemption_invite.token
        allow(RedemptionInviteMailer).to receive(:invite)

        do_patch

        expect(redemption_invite.reload.token).to eq(original_token)
        expect(RedemptionInviteMailer).not_to have_received(:invite)
      end
    end

    context 'when validation fails' do
      let(:update_params) do
        {
          recipient_name: 'A' * 300, # Exceeds maximum length
          recipient_email: 'invalid-email'
        }
      end

      it 'does not update the redemption invite' do
        expect { do_patch }.not_to(change { redemption_invite.reload.attributes })
      end

      it 'redirects back with error flash' do
        do_patch

        expect(response).to have_http_status(:redirect)
        expect(flash[:error]).to be_present
        expect(flash[:error]).to include('name is too long')
        expect(flash[:error]).to include('email must be a valid email address')
      end
    end

    context 'when user does not own the subscription' do
      let(:other_user) { create(:user) }
      let(:other_subscription) { create(:subscription, subscriber: other_user) }
      let(:redemption_invite) { create(:redemption_invite, subscription: other_subscription) }

      it 'raises an authorization error' do
        expect { do_patch }.to raise_error(/does not own Subscription/)
      end
    end

    context 'when not logged in' do
      before do
        sign_out(user)
      end

      it 'redirects to login page' do
        do_patch

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when redemption invite does not exist' do
      it 'raises record not found error' do
        patch :update, params: { id: 'nonexistent', redemption_invite: update_params }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when recipient_email changes from blank to a value' do
      let(:redemption_invite) { create(:redemption_invite, subscription: subscription, recipient_email: '') }
      let(:update_params) { { recipient_email: 'new@example.com' } }

      it 'resets token and sends email' do
        allow(RedemptionInviteMailer).to receive(:invite).and_return(mailer_double)

        expect { do_patch }.to(change { redemption_invite.reload.token })
        expect(flash[:notice]).to include('email sent')
      end
    end

    context 'when recipient_email changes from a value to blank' do
      let(:update_params) { { recipient_email: '' } }

      it 'does not send email' do
        allow(RedemptionInviteMailer).to receive(:invite).and_return(mailer_double)

        do_patch

        expect(RedemptionInviteMailer).not_to have_received(:invite)
      end
    end

    context 'when trimming whitespace from inputs' do
      let(:update_params) do
        {
          recipient_name: '  Trimmed Name  ',
          recipient_email: '  trimmed@example.com  '
        }
      end

      it 'trims whitespace from inputs' do
        do_patch

        redemption_invite.reload
        expect(redemption_invite.recipient_name).to eq('Trimmed Name')
        expect(redemption_invite.recipient_email).to eq('trimmed@example.com')
      end
    end
  end
end
