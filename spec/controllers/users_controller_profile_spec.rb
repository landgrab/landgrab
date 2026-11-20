# frozen_string_literal: true

RSpec.describe UsersController do
  render_views

  describe 'GET users#profile' do
    subject(:do_get) { get :profile, params: { username: profile_user.username } }

    let(:profile_user) { create(:user, username: 'jane') }
    let(:expected_url) { referral_url(referral_token: profile_user.referral_token) }

    context 'when viewing your own profile' do
      before { sign_in(profile_user) }

      it 'shows a copy button instead of a clickable referral link' do
        do_get

        expect(response.body).to include('Copy referral link')
        expect(response.body).not_to include(%(href="#{expected_url}"))
      end
    end

    context 'when viewing someone else\'s profile' do
      before { sign_in(create(:user)) }

      it 'shows the clickable referral link' do
        do_get

        expect(response.body).to include(%(href="#{expected_url}"))
        expect(response.body).not_to include('Copy referral link')
      end
    end

    context 'when logged out' do
      it 'shows the clickable referral link' do
        do_get

        expect(response.body).to include(%(href="#{expected_url}"))
      end
    end
  end

  describe 'GET users#me' do
    subject(:do_get) { get :me }

    let(:user) { create(:user, username: nil) }

    before { sign_in(user) }

    it 'shows a copy button for the referral link' do
      do_get

      expect(response.body).to include('Copy referral link')
    end
  end
end
