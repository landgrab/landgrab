# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationsController do
  before { @request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET registrations#referral' do
    let(:referrer) { create(:user) }

    it 'stores the referral token in the session and redirects to sign up' do
      get :referral, params: { referral_token: referrer.referral_token }

      expect(session[:referral_token]).to eq referrer.referral_token
      expect(response).to redirect_to(new_user_registration_path)
    end
  end

  describe 'POST registrations#create' do
    let(:referrer) { create(:user) }

    def do_post
      post :create, params: { user: {
        first_name: 'New',
        last_name: 'User',
        email: 'new@example.com',
        password: 'password',
        password_confirmation: 'password'
      } }
    end

    context 'when a referral token is present in the session' do
      before { session[:referral_token] = referrer.referral_token }

      it 'associates the new user with the referrer' do
        do_post

        expect(User.find_by(email: 'new@example.com').referrer).to eq referrer
      end

      it 'clears the referral token from the session after use' do
        do_post

        expect(session[:referral_token]).to be_nil
      end
    end

    context 'when no referral token is in the session' do
      it 'creates the user without a referrer' do
        do_post

        expect(User.find_by(email: 'new@example.com').referrer).to be_nil
      end
    end

    context 'when the referral token does not match any user' do
      before { session[:referral_token] = 'doesnotexist' }

      it 'creates the user without a referrer' do
        do_post

        expect(User.find_by(email: 'new@example.com').referrer).to be_nil
      end
    end
  end
end
