# frozen_string_literal: true

RSpec.describe Admin::ProjectsController do
  render_views

  let(:admin) { create(:user, admin: true) }
  let(:project) { create(:project) }

  before { sign_in(admin, scope: :user) }

  describe 'GET show' do
    it 'links to a new post about the project' do
      get :show, params: { id: project.hashid }

      link = response.parsed_body.xpath("//a[normalize-space()='Create a post about this project']").first
      expect(link['href']).to eq new_admin_post_path(postable_type: 'Project', postable_id: project.hashid)
    end
  end
end
