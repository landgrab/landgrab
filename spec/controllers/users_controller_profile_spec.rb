# frozen_string_literal: true

RSpec.describe UsersController do
  render_views

  describe 'GET users#profile' do
    subject(:do_get) { get :profile, params: { username: profile_user.username } }

    let(:profile_user) { create(:user, username: 'jane') }
    let(:expected_url) { referral_url(referral_token: profile_user.referral_token) }

    context 'when viewing your own profile' do
      before { sign_in(profile_user) }

      it 'shows a copy button instead of a clickable referral link' do
        do_get

        expect(response.body).to include('Copy referral link')
        expect(response.body).not_to include(%(href="#{expected_url}"))
      end
    end

    context 'when viewing someone else\'s profile' do
      before { sign_in(create(:user)) }

      it 'shows the clickable referral link' do
        do_get

        expect(response.body).to include(%(href="#{expected_url}"))
        expect(response.body).not_to include('Copy referral link')
      end
    end

    context 'when logged out' do
      it 'shows the clickable referral link' do
        do_get

        expect(response.body).to include(%(href="#{expected_url}"))
      end
    end

    context 'when the profile user has no tiles' do
      it 'says so' do
        do_get

        expect(response.body).to include('No tiles yet.')
        expect(response.body).not_to include('Refer friends and their tiles show up here.')
      end

      it 'nudges you to refer friends on your own profile' do
        sign_in(profile_user)
        do_get

        expect(response.body).to include('Refer friends and their tiles show up here.')
      end
    end

    context 'when the profile user has redeemed, gifted and referred tiles' do
      let(:stranger) { create(:user) }
      let(:referee) { create(:user, referrer: profile_user) }
      let(:busy_plot) { create(:plot, title: 'Busy Plot', polygon: square_polygon(0)) }
      let(:quiet_plot) { create(:plot, title: 'Quiet Plot', polygon: square_polygon(1)) }

      before do
        subscribe(plot: quiet_plot, subscriber: profile_user, redeemer: profile_user)
        subscribe(plot: busy_plot, subscriber: profile_user, redeemer: stranger)
        subscribe(plot: busy_plot, subscriber: referee, redeemer: referee)
        subscribe(plot: busy_plot, subscriber: stranger, redeemer: referee)
        subscribe(plot: create(:plot, title: 'Ignored Plot', polygon: square_polygon(2)), subscriber: stranger, redeemer: stranger)
      end

      def square_polygon(offset)
        lng = offset * 0.01
        "POLYGON ((#{lng} 51.5, #{lng + 0.001} 51.5, #{lng + 0.001} 51.501, #{lng} 51.501, #{lng} 51.5))"
      end

      def subscribe(plot:, subscriber:, redeemer:)
        create(:subscription, tile: create(:tile, plot:), subscriber:, redeemer:)
      end

      it 'summarises the impact and shows a map per plot, busiest first' do
        do_get

        expect(response.body).to include('Freya has').and include('1 tile, 1 gifted tile, and 1 referred tile across 2 plots')
        expect(response.body.index('Freya&#39;s impact in Busy Plot')).to be < response.body.index('Freya&#39;s impact in Quiet Plot')
        expect(response.body).not_to include('Ignored Plot')
      end

      it 'says "My" on your own profile' do
        sign_in(profile_user)
        do_get

        expect(response.body).to include('You have').and include('My impact in Busy Plot')
      end
    end
  end

  describe 'GET users#me' do
    subject(:do_get) { get :me }

    let(:user) { create(:user, username: nil) }

    before { sign_in(user) }

    it 'shows a copy button for the referral link' do
      do_get

      expect(response.body).to include('Copy referral link')
    end
  end
end
