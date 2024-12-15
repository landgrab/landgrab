# frozen_string_literal: true

source 'https://rubygems.org'

# IMPORTANT: If changing, also update;
# - .ruby-version file (`rbenv local X.Y.Z`)
# - RuboCop's TargetRubyVersion
# - Dockerfile FROM image definition
ruby '3.3.3'

# IMPORTANT: When upgrading Rails, follow all instructions!
# Eg. run `app:update` script, action `new_framework_defaults_*.rb`, update `config.load_defaults`
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
gem 'rails', '~> 7.0' # REMEMBER TO `app:update` AFTER CHANGING

# Support PostGIS (spatial PostgreSQL extension)
gem 'activerecord-postgis-adapter'

# Remove whitespace in user-supplied data
gem 'auto_strip_attributes'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Pagination (Kaminari) styling for Bootstrap
gem 'bootstrap5-kaminari-views'

# Security audit checks (eg. SQL injection)
gem 'brakeman', require: false, group: %i[development test]

# Track down N+1 queries and unused eager loading
gem 'bullet', group: %i[development test]

# Call 'byebug' anywhere in the code to stop execution and get a debugger console
gem 'byebug', groups: %i[development test]

# CSV building (for data export)
gem 'csv'

# User authentication
gem 'devise'

# Shim to load environment variables from .env into ENV in development.
gem 'dotenv-rails', groups: %i[development test]

# Use factories for creating test objects
gem 'factory_bot_rails', group: %i[development test]

# Dependency of RGeo operation with 'geos' library
gem 'ffi-geos', groups: %i[development test]

# Identify inconsistencies between model config and database constraints
gem 'guard-consistency_fail', group: :development

# Automatic test running
gem 'guard-rspec', require: false, group: :development

# Run RuboCop via Guard
gem 'guard-rubocop', group: :development

# Apply scopes (filters) based on params
gem 'has_scope'

# Replace raw numeric IDs with short unique ids
gem 'hashid-rails'

# JSON APIs
gem 'jbuilder'

# Pagination support
gem 'kaminari'

# Listener for filesystem changes
gem 'listen', groups: %i[development test]

# Handling currency objects
gem 'money-rails'

# PostgreSQL database wrapper
gem 'pg'

# Postmarkapp.com email sending
gem 'postmark-rails'

# Puma app server
gem 'puma'

# TODO: Remove once rack version Stripe Webhook issue resolved
gem 'rack', '3.0'

# Markdown editor
gem 'redcarpet'

# Render RGeo (from PostGis) as GeoJSON
gem 'rgeo-geojson'

# RSpec test framework
gem 'rspec-rails', groups: %i[development test]

# RuboCop code linting
gem 'rubocop', groups: %i[development test]
gem 'rubocop-factory_bot', groups: %i[development test]
gem 'rubocop-performance', groups: %i[development test]
gem 'rubocop-rails', groups: %i[development test]
gem 'rubocop-rspec', groups: %i[development test]
gem 'rubocop-rspec_rails', groups: %i[development test]
gem 'rubocop-thread_safety', groups: %i[development test]

# RuboCop for view files
gem 'ruumba', groups: %i[development test]

# Sentry.io Error Reporting
gem 'sentry-rails'
gem 'sentry-ruby'

# Language Server for IDE enhancement / 'Intellisense'
gem 'solargraph', group: :development

# Payments
gem 'stripe'

# Detect misconfigured routes
gem 'traceroute', groups: %i[development test]

# Access an interactive console on exception pages or by calling 'console' anywhere in the code.
gem 'web-console', group: :development

# Mock web requests during tests
gem 'webmock', group: :test
