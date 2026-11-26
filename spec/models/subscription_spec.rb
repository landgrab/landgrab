# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscription do
  describe '#assign_latest_subscription' do
    let(:subscr) { create(:subscription, tile: nil) }
    let(:tile) { create(:tile) }

    it 'assigns subscription as latest_subscription for tile' do
      expect { subscr.update(tile:) }.to change { tile.reload.latest_subscription }.from(nil).to(subscr)
    end
  end

  describe '.usable' do
    it 'includes active, trialing and past_due subscriptions only' do
      statuses = described_class.stripe_statuses.keys
      subs = statuses.index_with { |status| create(:subscription, stripe_status: status) }

      expect(described_class.usable).to match_array(subs.values_at('active', 'trialing', 'past_due'))
    end
  end

  describe '#usable_stripe_status?' do
    it 'agrees with the usable scope' do
      described_class.stripe_statuses.each_key do |status|
        subscription = create(:subscription, stripe_status: status)

        expect(subscription.usable_stripe_status?).to eq(described_class.usable.exists?(subscription.id))
      end
    end
  end

  describe 'viewing' do
    let(:user) { create(:user) }
    let(:subscription) { create(:subscription, subscriber: create(:user), redeemer: user) }

    it 'lets the subscriber and the redeemer view while usable' do
      expect([subscription.subscriber, user].map { |u| subscription.viewable_by?(u) }).to eq([true, true])
    end

    it 'agrees with the viewable_by scope' do
      expect(described_class.viewable_by(user)).to contain_exactly(subscription)
    end

    it 'lets nobody view once cancelled' do
      subscription.update!(stripe_status: 'canceled')

      expect([subscription.viewable_by?(user), described_class.viewable_by(user).exists?]).to eq([false, false])
    end
  end
end
