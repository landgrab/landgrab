# frozen_string_literal: true

RSpec.describe Admin::PromoCodesController do
  render_views

  let(:admin) { create(:user, admin: true) }

  before { sign_in(admin, scope: :user) }

  describe 'GET index' do
    it 'lists promo codes including free-trial codes' do
      create(:promo_code, code: 'STRIPEONE')
      create(:promo_code, :free_trial, code: 'TRIALONE')

      get(:index)

      expect(response.body).to include('STRIPEONE', 'TRIALONE')
    end

    it 'rejects if not admin' do
      admin.update!(admin: false)

      get(:index)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET show' do
    it 'shows the promo code' do
      promo_code = create(:promo_code, :free_trial, code: 'TRIALONE')

      get(:show, params: { id: promo_code.hashid })

      expect(response.body).to include('TRIALONE', '14 days')
    end
  end

  describe 'POST create' do
    it 'creates a promo code' do
      expect do
        post(:create, params: { promo_code: { code: 'NEWCODE', stripe_id: 'promo_new1' } })
      end.to change(PromoCode, :count).by(1)

      expect(response).to redirect_to(admin_promo_code_path(PromoCode.last))
    end

    it 're-renders the form when invalid' do
      expect do
        post(:create, params: { promo_code: { code: '', stripe_id: 'bad' } })
      end.not_to change(PromoCode, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'PATCH update' do
    let(:promo_code) { create(:promo_code) }

    it 'updates the promo code' do
      patch(:update, params: { id: promo_code.hashid, promo_code: { code: 'RENAMED' } })

      expect(promo_code.reload.code).to eq('RENAMED')
    end

    it 're-renders the form when invalid' do
      patch(:update, params: { id: promo_code.hashid, promo_code: { stripe_id: 'bad' } })

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
