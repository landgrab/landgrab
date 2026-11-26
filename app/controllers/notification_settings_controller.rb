# frozen_string_literal: true

class NotificationSettingsController < ApplicationController
  def edit; end

  def update
    if current_user.update(notification_params)
      redirect_to edit_notification_settings_path, notice: 'Your notification settings have been saved.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def notification_params
    params.expect(user: [:bulletin_emails])
  end
end
