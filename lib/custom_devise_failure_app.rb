# frozen_string_literal: true

class CustomDeviseFailureApp < Devise::FailureApp
  # Redirect to the sign up page on failed auth
  # https://github.com/heartcombo/devise/wiki/Redirect-to-new-registration-(sign-up)-path-if-unauthenticated
  def route(_scope)
    :new_user_registration_url
  end
end
