# frozen_string_literal: true

RSpec.describe BulletinOneClickUnsubscribesController do
  let(:user) { create(:user) }
  let(:token) { user.generate_token_for(:bulletin_unsubscribe) }

  describe 'POST bulletin_one_click_unsubscribes#create' do
    it 'turns bulletin emails off for the token\'s user without a login or CSRF token' do
      post :create, params: { token:, 'List-Unsubscribe': 'One-Click' }

      expect(response).to have_http_status(:ok)
      expect(user.reload.bulletin_emails).to be false
    end

    it 'only affects the user the token was issued for' do
      other = create(:user)

      post :create, params: { token: }

      expect(other.reload.bulletin_emails).to be true
    end

    it 'leaves everyone alone when the token is invalid' do
      post :create, params: { token: 'nonsense' }

      expect(response).to have_http_status(:not_found)
      expect(user.reload.bulletin_emails).to be true
    end
  end
end
