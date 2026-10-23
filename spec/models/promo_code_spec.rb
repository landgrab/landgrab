# frozen_string_literal: true

RSpec.describe PromoCode do
  it 'requires a promo_ Stripe ID for ordinary codes' do
    expect(build(:promo_code, stripe_id: nil)).not_to be_valid
  end

  it 'allows free trial codes without a Stripe ID' do
    expect(build(:promo_code, :free_trial)).to be_valid
  end

  it 'rejects a Stripe ID on free trial codes' do
    expect(build(:promo_code, :free_trial, stripe_id: 'promo_abc123')).not_to be_valid
  end

  it 'rejects non-positive trial lengths' do
    expect(build(:promo_code, :free_trial, free_trial_days: 0)).not_to be_valid
  end
end
