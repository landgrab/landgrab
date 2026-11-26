# frozen_string_literal: true

RSpec.describe Admin::PricesController do
  render_views

  before do
    sign_in(create(:user, admin: true), scope: :user)
    # db:setup seeds prices, so start from none (rolled back with the example's transaction)
    Price.delete_all
  end

  describe 'GET index with none' do
    it_behaves_like 'an admin index with a single empty state', 'No prices found'
  end
end
