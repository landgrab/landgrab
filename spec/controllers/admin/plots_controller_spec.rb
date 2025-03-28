# frozen_string_literal: true

RSpec.describe Admin::PlotsController do
  describe 'PATCH update' do
    let(:admin) { create(:user, admin: true) }
    let(:plot) { create(:plot) }

    let(:plot_params) { attributes_for(:plot) }

    before do
      allow(PlotTilesPopulateJob).to receive(:perform_later)
      sign_in(admin, scope: :user)
    end

    it 'redirects to the plot details' do
      patch(:update, params: { id: plot.hashid, plot: plot_params })

      expect(response).to redirect_to admin_plot_path(plot)
    end

    it 'rejects if not admin' do
      admin.update!(admin: false)

      patch(:update, params: { id: plot.hashid, plot: plot_params })

      expect(response).to have_http_status(:not_found)
    end

    it 'does not run tile population job if polygon unchanged' do
      patch(:update, params: { id: plot.hashid, plot: plot_params })

      expect(PlotTilesPopulateJob).not_to have_received(:perform_later)
    end

    it 'runs tile population job if polygon changed' do
      changed_polygon = 'POLYGON ((-0.02018 51.51576, -0.02002 51.51591, -0.01981 51.51559, -0.02018 51.51576))'
      patch(:update, params: { id: plot.hashid, plot: plot_params.merge(polygon: changed_polygon) })

      expect(PlotTilesPopulateJob).to have_received(:perform_later).with(plot.id)
    end
  end
end
