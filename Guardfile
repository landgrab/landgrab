# frozen_string_literal: true

##########################
# Guardfile for Landgrab #
##########################

# This group allows to skip running RuboCop when RSpec failed.
group :red_green_refactor, halt_on_fail: true do
  # See https://github.com/guard/guard-rspec
  rspec_options = {
    cmd: 'bin/rspec',
    cmd_additional_args: '--no-profile'
  }
  guard :rspec, rspec_options do
    require 'guard/rspec/dsl'
    dsl = Guard::RSpec::Dsl.new(self)

    # RSpec files
    rspec = dsl.rspec
    watch(rspec.spec_helper) { rspec.spec_dir }
    watch(rspec.spec_support) { rspec.spec_dir }
    watch(rspec.spec_files) do |m|
      [
        m[0] # run the changed spec file!
      ]
    end

    # Ruby files
    ruby = dsl.ruby
    dsl.watch_spec_files_for(ruby.lib_files)

    # Rails files
    rails = dsl.rails(view_extensions: %w[erb haml slim])
    dsl.watch_spec_files_for(rails.app_files)
    dsl.watch_spec_files_for(rails.views)

    # Controllers
    watch(rails.controllers) do |m|
      [
        "#{rspec.spec_dir}/requests/#{m[1]}_request_spec.rb"
      ]
    end

    # Services
    watch(%r{^app/services/(.+)\.rb$}) { |m| "#{rspec.spec_dir}/services/#{m[1]}_spec.rb" }

    # Jobs
    watch(%r{^app/jobs/(.+)\.rb$}) { |m| "#{rspec.spec_dir}/jobs/#{m[1]}_spec.rb" }

    # Mailers
    watch(%r{^app/mailers/(.+)\.rb$}) { |m| "#{rspec.spec_dir}/mailers/#{m[1]}_spec.rb" }

    # FactoryBot (previously "FactoryGirl") Factories
    watch(%r{^spec/factories/(.+)\.rb$}) do |m|
      [
        "#{rspec.spec_dir}/models/#{m[1].singularize}_spec.rb",
        "#{rspec.spec_dir}/factory_bot_spec.rb"
      ]
    end

    # Rails config changes
    watch(rails.spec_helper) { rspec.spec_dir }

    watch(rails.app_controller) do
      [
        "#{rspec.spec_dir}/controllers",
        "#{rspec.spec_dir}/requests"
      ]
    end
  end

  guard :rubocop, all_on_start: false do
    %w[Gemfile config.ru].each do |file|
      watch("./#{file}")
    end

    watch(/.+\.rb$/)
    watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
    watch(%r{lib/tasks/.+\.rake$})

    # this is so the Guardfile gets scanned by rubocop and the result outputted into the console
    callback(:start_end) do
      puts `rubocop Guardfile`
    end
  end
end

guard :consistency_fail do
  watch(%r{^app/model/(.+)\.rb})
  watch(%r{^db/schema.rb})
end
