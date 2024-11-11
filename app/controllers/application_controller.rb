# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :store_location

  protected

  def configure_permitted_parameters
    keys = %i[first_name last_name]
    devise_parameter_sanitizer.permit(:sign_up, keys:)
    devise_parameter_sanitizer.permit(:account_update, keys:)
  end

  # Store current URL for use in post-login/register redirect.
  def store_location
    return if user_signed_in?
    return if request.post?
    return unless request.format.html? # skip JSON/CSV etc.
    return if %w[
      /
      /users/sign_in
      /users/sign_up
      /users/password/new
    ].include?(request.path)

    store_location_for(:user, request.fullpath)
  end

  # Devise: Path for sending users to after they log in or register
  def after_sign_in_path_for(_resource)
    stored_location_for(:user) || root_path
  end

  def log_event_mixpanel(event_type, event_data = {})
    flash['a'] ||= {}
    flash['a']['mixpanel'] ||= []
    flash['a']['mixpanel'] << { 'event_type' => event_type, 'event_data' => event_data }
  end

  private

  def check_admin
    return if current_user&.admin?

    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end

  def ensure_stripe_enrollment
    return if current_user.stripe_customer_id.present?

    StripeCustomerCreateJob.perform_now(current_user)

    current_user.reload
  end

  def render_csv(filename_prefix)
    filename = "#{filename_prefix}-#{Time.zone.now.strftime('%Y-%m-%dT%H-%M-%S')}.csv"
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}"
  end
end
