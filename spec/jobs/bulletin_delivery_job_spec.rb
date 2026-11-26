# frozen_string_literal: true

RSpec.describe BulletinDeliveryJob do
  include ActiveSupport::Testing::TimeHelpers

  subject(:perform) { described_class.perform_now(delivery) }

  let(:user) { create(:user, email: 'freya@example.com') }
  let(:bulletin) { create(:bulletin) }
  let(:delivery) { create(:bulletin_delivery, bulletin:, user:) }

  before { ActionMailer::Base.deliveries.clear }

  it 'sends the bulletin email to the user' do
    perform

    expect(ActionMailer::Base.deliveries.map(&:to)).to eq [['freya@example.com']]
  end

  it 'records when it was sent and where' do
    freeze_time do
      perform

      expect(delivery.reload).to have_attributes(sent_at: Time.zone.now, email: 'freya@example.com', failed_at: nil)
    end
  end

  it 'sends to the address the user has now, and records that one' do
    delivery
    user.update!(email: 'new@example.com')

    perform

    expect(ActionMailer::Base.deliveries.last.to).to eq ['new@example.com']
    expect(delivery.reload.email).to eq 'new@example.com'
  end

  it 'does not send twice' do
    perform

    expect { described_class.perform_now(delivery) }.not_to(change { ActionMailer::Base.deliveries.count })
  end

  it 'does not send to a user who unsubscribed since the bulletin was confirmed' do
    user.update!(bulletin_emails: false)

    expect { perform }.not_to(change { ActionMailer::Base.deliveries.count })
    expect(delivery.reload).to have_attributes(sent_at: nil, error: 'The user unsubscribed before this was sent')
    expect(delivery).to be_failed
  end

  it 'records a failure when the user has been deleted' do
    delivery.update!(user: nil)

    perform

    expect(delivery.reload.error).to eq 'The user no longer exists'
  end

  context 'when sending fails' do
    before { allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(Net::ReadTimeout) } # rubocop:disable RSpec/AnyInstance

    it 'records the failure instead of raising' do
      expect { perform }.not_to raise_error

      expect(delivery.reload).to have_attributes(sent_at: nil, error: 'Net::ReadTimeout: Net::ReadTimeout')
      expect(delivery).to be_failed
    end
  end
end
