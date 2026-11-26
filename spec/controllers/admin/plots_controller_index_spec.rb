# frozen_string_literal: true

RSpec.describe Admin::PlotsController do
  render_views

  before { sign_in(create(:user, admin: true), scope: :user) }

  describe 'GET index with none' do
    it_behaves_like 'an admin index with a single empty state', 'No plots found'
  end
end
