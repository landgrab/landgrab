# frozen_string_literal: true

RSpec.describe StripeCustomerCreateJob do
  subject(:job) { described_class.new }

  let(:user) { create(:user) }

  describe '#perform' do
    context 'with no existing customer' do
      before do
        stub_stripe_api(:get, 200, 'customers/search', 'customers/search/empty', "query=email:'#{user.email}'")
        stub_stripe_api(:post, 200, 'customers', 'customers/create')
      end

      it 'creates a Stripe customer' do
        expect { job.perform(user) }.to change(user, :stripe_customer_id).to('cus_aoeuidhtns')
      end
    end

    context 'with an existing customer matching by email' do
      before do
        stub_stripe_api(:get, 200, 'customers/search', 'customers/search/one', "query=email:'#{user.email}'")
      end

      it 'assigns found Stripe customer id' do
        expect { job.perform(user) }.to change(user, :stripe_customer_id).to('cus_bbddnnggdd')
      end
    end
  end
end
