# frozen_string_literal: true

source 'https://rubygems.org'

# IMPORTANT: If changing, also update;
# - .ruby-version file (`rbenv local X.Y.Z`)
# - RuboCop's TargetRubyVersion
# - Dockerfile FROM image definition
ruby '3.3.1'

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

# User authentication
gem 'devise'

# Shim to load environment variables from .env into ENV in development.
gem 'dotenv-rails', groups: %i[development test]

# Use factories for creating test objects
gem 'factory_bot_rails', group: %i[development test]

# Dependency of RGeo operation with 'geos' library
gem 'ffi-geos', groups: %i[development test]

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

# Markdown editor
gem 'redcarpet'

# Render RGeo (from PostGis) as GeoJSON
gem 'rgeo-geojson'

# RSpec test framework
gem 'rspec-rails', groups: %i[development test]

# RuboCop code linting
gem 'rubocop'
gem 'rubocop-factory_bot'
gem 'rubocop-performance'
gem 'rubocop-rails'
gem 'rubocop-rspec'
gem 'rubocop-thread_safety'

# RuboCop for view files
gem 'ruumba'

# Sentry.io Error Reporting
gem 'sentry-rails'
gem 'sentry-ruby'

# Language Server for IDE enhancement / 'Intellisense'
gem 'solargraph', group: :development

# Payments
gem 'stripe'

# Detect misconfigured routes
gem 'traceroute', group: %i[development test]

# Access an interactive console on exception pages or by calling 'console' anywhere in the code.
gem 'web-console', groups: :development

# Mock web requests during tests
gem 'webmock', group: :test
