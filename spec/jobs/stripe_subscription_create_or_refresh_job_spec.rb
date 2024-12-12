# frozen_string_literal: true

RSpec.describe StripeSubscriptionCreateOrRefreshJob do
  subject(:job) { described_class.new }

  let(:user) { create(:user, stripe_customer_id: 'cus_abc123') }
  let(:tile) { create(:tile) }
  let(:project) { create(:project) }

  describe '#perform' do
    subject(:perform) { job.perform('sub_123') }

    let(:subscription_body) { stripe_fixture('subscriptions/success') }

    before do
      # HACK: Workaround for some leftover test data?
      RedemptionInvite.destroy_all
      Subscription.destroy_all

      user
    end

    context 'with no metadata set' do
      before do
        stub_stripe_api(:get, 200, 'subscriptions/sub_123', subscription_body)
      end

      it 'creates a new subscription' do
        expect { perform }.to change(Subscription, :count).by(1)
      end

      it 'sets the subscriber' do
        subscription = perform

        expect(subscription.subscriber).to eq(user)
      end
    end

    context 'when redemption_mode set to SELF in metadata' do
      before do
        subscription_body[:metadata][:redemption_mode] = 'self'
        stub_stripe_api(:get, 200, 'subscriptions/sub_123', subscription_body)
      end

      it 'sets the redeemer on the subscription' do
        subscription = perform

        expect(subscription.redeemer).to eq user
      end
    end

    context 'with project set in metadata' do
      before do
        subscription_body[:metadata][:project] = project.hashid
        stub_stripe_api(:get, 200, 'subscriptions/sub_123', subscription_body)
      end

      it 'sets the project on the subscription' do
        subscription = perform

        expect(subscription.project).to eq project
      end
    end

    context 'with tile set in metadata' do
      before do
        subscription_body[:metadata][:tile] = tile.hashid
        stub_stripe_api(:get, 200, 'subscriptions/sub_123', subscription_body)
      end

      it 'sets the tile on the subscription' do
        subscription = perform

        expect(subscription.tile).to eq tile
      end

      it 'does not set tile if tile already linked to another subscription' do
        create(:subscription, tile:)

        subscription = perform

        expect(subscription.tile).to be_nil
      end
    end
  end
end
