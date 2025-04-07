# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    before_action :check_admin

    def dashboard
      render 'admin/dashboard'
    end

    def settings; end
  end
end
