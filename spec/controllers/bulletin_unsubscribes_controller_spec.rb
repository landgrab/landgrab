# frozen_string_literal: true

RSpec.describe BulletinUnsubscribesController do
  render_views

  let(:user) { create(:user) }
  let(:token) { user.generate_token_for(:bulletin_unsubscribe) }

  describe 'GET bulletin_unsubscribes#show' do
    it 'asks for confirmation without unsubscribing, even when signed out' do
      get :show, params: { token: }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Unsubscribe')
      expect(user.reload.bulletin_emails).to be true
    end

    it 'rejects an invalid token' do
      get :show, params: { token: 'nonsense' }

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('not valid')
    end
  end

  describe 'POST bulletin_unsubscribes#create' do
    it 'turns bulletin emails off without needing a login' do
      post :create, params: { token: }

      expect(response).to have_http_status(:ok)
      expect(user.reload.bulletin_emails).to be false
    end

    it 'leaves everyone alone when the token is invalid' do
      post :create, params: { token: 'nonsense' }

      expect(response).to have_http_status(:not_found)
      expect(user.reload.bulletin_emails).to be true
    end

    it 'only affects the user the token was issued for' do
      other = create(:user)

      post :create, params: { token: }

      expect(other.reload.bulletin_emails).to be true
    end
  end
end
