# frozen_string_literal: true

desc 'Traceroute with patch for Rails 8+ and ActiveStorage'
# See: https://github.com/amatsuda/traceroute/issues/49
task patched_traceroute: :environment do
  Rails.application.reload_routes_unless_loaded
  Rake::Task[:traceroute].execute
end
