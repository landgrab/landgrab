# frozen_string_literal: true

RSpec.describe Admin::BulletinsController do
  render_views

  let(:admin) { create(:user, admin: true) }
  let(:post_record) { create(:post, :viewed_by_subscriber, title: 'Spring planting', published_at: 1.day.ago) }

  before { sign_in(admin, scope: :user) }

  describe 'access' do
    it 'rejects non-admins' do
      admin.update!(admin: false)

      get(:index)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET index' do
    it 'lists bulletins with their status and delivery counts' do
      bulletin = create(:bulletin, subject: 'Spring news', posts: [post_record])
      BulletinConfirmationService.call(bulletin)
      bulletin.deliveries.first.update!(sent_at: Time.zone.now)

      get(:index)

      expect(response.body).to include('Spring news', 'Spring planting', 'SENT')
    end
  end

  describe 'GET index with no bulletins' do
    it 'says so once' do
      get(:index)

      expect(response.body.scan('No bulletins found').size).to eq 1
    end
  end

  describe 'POST create' do
    it 'creates a draft with the chosen posts, authored by the admin' do
      post(:create, params: { bulletin: { subject: 'News', intro: 'Hi', post_ids: [post_record.hashid] } })

      bulletin = Bulletin.last
      expect(bulletin).to have_attributes(subject: 'News', author: admin, posts: [post_record])
      expect(response).to redirect_to(admin_bulletin_path(bulletin))
    end

    it 're-renders with the audience error when the posts have different viewers' do
      other = create(:post, :viewed_by_subscriber)

      post(:create, params: { bulletin: { subject: 'News', post_ids: [post_record.hashid, other.hashid] } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('must all have exactly the same viewers')
    end
  end

  describe 'PATCH update' do
    it 'changes the subject and posts' do
      bulletin = create(:bulletin, posts: [create(:post, :viewed_by_subscriber)])

      patch(:update, params: { id: bulletin.hashid, bulletin: { subject: 'Renamed', post_ids: [post_record.hashid] } })

      expect(bulletin.reload).to have_attributes(subject: 'Renamed', posts: [post_record])
    end

    it 'changes nothing when the new posts are invalid' do
      original = create(:post, :viewed_by_subscriber)
      bulletin = create(:bulletin, posts: [original])

      patch(:update, params: { id: bulletin.hashid, bulletin: { subject: 'Renamed', post_ids: [post_record.hashid, original.hashid] } })

      expect(bulletin.reload).to have_attributes(subject: 'Spring news', posts: [original])
    end

    it 'refuses to change a confirmed bulletin' do
      bulletin = create(:bulletin, posts: [post_record])
      BulletinConfirmationService.call(bulletin)

      patch(:update, params: { id: bulletin.hashid, bulletin: { subject: 'Renamed' } })

      expect(bulletin.reload.subject).to eq 'Spring news'
    end
  end

  describe 'GET show' do
    it 'shows the audience size for a draft' do
      bulletin = create(:bulletin, posts: [post_record])

      get(:show, params: { id: bulletin.hashid })

      expect(response.body).to include('1 user can view these posts')
    end

    it 'shows the deliveries for a confirmed bulletin' do
      bulletin = create(:bulletin, posts: [post_record])
      BulletinConfirmationService.call(bulletin)
      bulletin.deliveries.first.update!(failed_at: Time.zone.now, error: 'Boom: it broke')

      get(:show, params: { id: bulletin.hashid })

      expect(response.body).to include('FAILED', 'Boom: it broke')
    end
  end

  describe 'GET preview' do
    it 'renders the email' do
      bulletin = create(:bulletin, posts: [post_record])

      get(:preview, params: { id: bulletin.hashid })

      expect(response.body).to include('Spring planting')
    end

    it 'explains when the content is too complex for email' do
      bulletin = create(:bulletin, intro: "| a |\n|---|\n| b |", posts: [post_record])

      get(:preview, params: { id: bulletin.hashid })

      expect(response).to redirect_to(admin_bulletin_path(bulletin))
      expect(flash[:error]).to include('a table')
    end
  end

  describe 'POST send_test' do
    it 'emails the admin without recording a delivery' do
      bulletin = create(:bulletin, posts: [post_record])
      ActionMailer::Base.deliveries.clear

      perform_enqueued_jobs { post(:send_test, params: { id: bulletin.hashid }) }

      expect(ActionMailer::Base.deliveries.map(&:to)).to eq [[admin.email]]
      expect(bulletin.deliveries).to be_empty
    end
  end

  describe 'POST confirm' do
    it 'confirms the bulletin and queues the emails' do
      bulletin = create(:bulletin, posts: [post_record])

      post(:confirm, params: { id: bulletin.hashid })

      expect(bulletin.reload).to be_confirmed
      expect(bulletin.deliveries.count).to eq 1
      expect(flash[:notice]).to include('1 email queued')
    end

    it 'stays a draft and says why when a post is not published' do
      bulletin = create(:bulletin, posts: [create(:post, :viewed_by_subscriber, published_at: nil)])

      post(:confirm, params: { id: bulletin.hashid })

      expect(bulletin.reload).not_to be_confirmed
      expect(flash[:error]).to include('is not published yet')
    end

    it 'cannot confirm twice' do
      bulletin = create(:bulletin, posts: [post_record])
      BulletinConfirmationService.call(bulletin)

      expect { post(:confirm, params: { id: bulletin.hashid }) }.not_to(change { bulletin.deliveries.count })
    end
  end

  describe 'DELETE destroy' do
    it 'deletes a draft' do
      bulletin = create(:bulletin, posts: [post_record])

      expect { delete(:destroy, params: { id: bulletin.hashid }) }.to change(Bulletin, :count).by(-1)
    end

    it 'keeps a confirmed bulletin' do
      bulletin = create(:bulletin, posts: [post_record])
      BulletinConfirmationService.call(bulletin)

      expect { delete(:destroy, params: { id: bulletin.hashid }) }.not_to change(Bulletin, :count)
    end
  end
end
