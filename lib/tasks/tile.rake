# frozen_string_literal: true

namespace :tile do
  desc "Populate tiles within a given plot's polygon"
  task populate_from_polygon: :environment do
    plot = Plot.find!(ENV.fetch('PLOT_ID'))

    PlotTilesPopulateJob.perform_now(plot.id)
  end

  desc 'Report mentions and post associations for subscribed tiles.'
  task report_mentions_and_associations: :environment do
    posts_data = Post.all.map do |post|
      {
        post: post,
        mentioned_tile_ids: post.mentioned_tiles.map(&:id),
        associated_tiles_ids: post.associated_tiles.map(&:id),
        associated_plots_ids: post.associated_plots.map(&:id),
        associated_projects_ids: post.associated_projects.map(&:id)
      }
    end

    print_header = true
    Tile.includes(:latest_subscription).find_each do |tile|
      subscribed = tile.latest_subscription.present?
      next unless subscribed

      mentioned = posts_data.select { |data| data[:mentioned_tile_ids].include?(tile.id) }
      associated = posts_data.select { |data| data[:associated_tiles_ids].include?(tile.id) }
      associated_via_plot = posts_data.select { |data| data[:associated_plots_ids].include?(tile.plot&.id) }
      associated_via_project = posts_data.select { |data| data[:associated_projects_ids].include?(tile.plot&.project_id) }
      data = {
        tile: tile.hashid,
        w3w: tile.w3w,
        latest_subscription_status: tile.latest_subscription&.stripe_status_readable || 'NOT SUBSCRIBED',
        mentioned_count: mentioned.size,
        mentioned_last: mentioned.map { |data| data[:post].created_at }.max&.to_date,
        associated_count: associated.size,
        associated_last: associated.map { |data| data[:post].created_at }.max&.to_date,
        associated_via_plot_count: associated_via_plot.size,
        associated_via_plot_last: associated_via_plot.map { |data| data[:post].created_at }.max&.to_date,
        associated_via_project_count: associated_via_project.size,
        associated_via_project_last: associated_via_project.map { |data| data[:post].created_at }.max&.to_date
      }
      if print_header
        puts data.keys.join(',')
        print_header = false
      end
      puts data.values.join(',')
    end
  end
end
