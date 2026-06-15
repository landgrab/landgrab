# frozen_string_literal: true

# Extends https://github.com/heartcombo/devise/blob/main/app/controllers/devise/registrations_controller.rb
class RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: %i[referral]

  def referral
    session[:referral_token] = params[:referral_token]
    redirect_to new_user_registration_path, flash: { notice: "You've been invited! Create an account to get started." }
  end

  def edit; end

  def edit_password
    set_minimum_password_length
  end

  def create
    super do |user|
      if user.persisted? && session[:referral_token].present?
        referrer = User.find_by(referral_token: session.delete(:referral_token))
        user.update!(referrer: referrer) if referrer && referrer != user
      end
    end
  end

  private

  def after_update_path_for(_resource)
    edit_profile_path
  end

  # Allow updating other attributes if replacement password is not provided
  def update_resource(resource, params)
    if params[:password].blank?
      params.delete('current_password')
      resource.update_without_password(params)
    else
      resource.update_with_password(params)
    end
  end
end
