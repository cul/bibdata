# frozen_string_literal: true

namespace :bibdata do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:rspec) do |spec|
    # Right now, 'redis' is the only available exclusion type
    exclusions = ENV['EXCLUDE_SPECS'].to_s.split(',') & ['redis']
    spec.rspec_opts = exclusions.map { |exclude| "--tag ~@#{exclude}" }

    spec.rspec_opts << '--backtrace' if ENV['CI']
  end

  require 'rubocop/rake_task'
  desc 'Run style checker'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << 'rubocop-rspec'
    task.fail_on_error = true
  end

  desc 'CI build without rubocop'
  task ci_nocop: [:environment, 'bibdata:ci_specs']

  desc 'CI build with Rubocop validation'
  task ci: [:environment, 'bibdata:rubocop', 'bibdata:ci_specs']

  desc 'CI build just running specs'
  task ci_specs: :environment do
    rspec_system_exit_failure_exception = nil

    duration = Benchmark.realtime do
      ENV['RAILS_ENV'] = 'test'
      Rails.env = ENV['RAILS_ENV']

      # puts "setting up test db...\n"
      # Rake::Task["db:environment:set"].invoke
      # Rake::Task["db:drop"].invoke
      # Rake::Task["db:create"].invoke
      # Rake::Task["db:migrate"].invoke
      begin
        Rake::Task['bibdata:rspec'].invoke
      rescue SystemExit => e
        rspec_system_exit_failure_exception = e
      end
    end
    puts "\nCI run finished in #{duration} seconds."
    # If present, re-raise any caught exit exception after CI duration display,
    # so we can still display the run time even when a system exception comes up.
    # This exception triggers an exit call with the original error code sent out by rspec failure.
    raise rspec_system_exit_failure_exception unless rspec_system_exit_failure_exception.nil?
  end
rescue LoadError => e
  # Be prepared to rescue so that this rake file can exist in environments where RSpec is unavailable (i.e. production environments).
  puts '[Warning] Exception creating ci/rubocop/rspec rake tasks. '\
    'This message can be ignored in environments that intentionally do not pull in certain development/test environment gems (i.e. production environments).'
  puts e
end
