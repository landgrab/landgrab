# frozen_string_literal: true

RSpec.describe NotificationSettingsController do
  render_views

  let(:user) { create(:user) }

  describe 'GET notification_settings#edit' do
    it 'redirects to sign in when signed out' do
      get :edit

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'shows the bulletin emails setting, switched on by default' do
      sign_in(user)

      get :edit

      expect(response.body).to include('Project update emails')
      expect(response.body).to match(/<input[^>]*type="checkbox"[^>]*checked/)
    end
  end

  describe 'PATCH notification_settings#update' do
    before { sign_in(user) }

    it 'turns bulletin emails off' do
      patch :update, params: { user: { bulletin_emails: '0' } }

      expect(user.reload.bulletin_emails).to be false
      expect(response).to redirect_to(edit_notification_settings_path)
    end

    it 'turns bulletin emails back on' do
      user.update!(bulletin_emails: false)

      patch :update, params: { user: { bulletin_emails: '1' } }

      expect(user.reload.bulletin_emails).to be true
    end

    it 'ignores attributes other than notification settings' do
      expect do
        patch :update, params: { user: { bulletin_emails: '0', admin: true } }
      end.not_to(change { user.reload.admin })
    end
  end
end
