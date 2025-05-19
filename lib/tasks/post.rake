# frozen_string_literal: true

namespace :post do
  desc 'Count views by unique users (excluding admins)'
  task count_unique_views: :environment do
    admin_ids = User.where(admin: true).pluck(:id)
    Post.includes(:post_views).each_with_index do |post, idx|
      views = post.post_views.reject { |view| admin_ids.include?(view.user_id) }
      view_count = views.map(&:user_id).uniq.count
      data = {
        post_hashid: post.hashid,
        title: post.title.tr(',', '_'),
        unique_non_admin_view_count: view_count
      }
      puts data.keys.join(',') if idx.zero?
      puts data.values.join(',')
    end
  end
end
