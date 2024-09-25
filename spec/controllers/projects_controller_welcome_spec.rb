# frozen_string_literal: true

RSpec.describe ProjectsController do
  render_views

  let(:user) { create(:user) }
  let(:project_welcome_text) { 'welcome to this test project' }
  let(:project) { create(:project, welcome_text: project_welcome_text) }
  let(:plot) { create(:plot, project:) }
  let(:tile) { create(:tile, plot:) }

  describe 'GET projects#welcome' do
    subject(:do_get) do
      get :welcome, params: { id: project.hashid }
    end

    before do
      sign_in(user)
    end

    context 'when logged out' do
      before do
        sign_out(user)
      end

      it 'redirects to login' do
        do_get

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when subscribed to a tile in current project' do
      before do
        create(:subscription, subscriber: user)
      end

      it 'returns a 200 status code' do
        do_get

        expect(response).to have_http_status(:ok)
      end

      it 'renders project welcome blurb' do
        do_get

        expect(response.body).to include(project_welcome_text)
      end
    end
  end
end
