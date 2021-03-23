# frozen_string_literal: true

require 'flatware/cli'
require 'flatware/rspec'
require 'flatware/rspec/formatters/console'
require 'flatware/rspec/job_builder'

module Flatware
  # rspec thor command
  class CLI
    worker_option
    method_option(
      'sink-endpoint',
      type: :string,
      default: 'drbunix:flatware-sink'
    )
    desc 'rspec [FLATWARE_OPTS]', 'parallelizes rspec'
    def rspec(*rspec_args)
      Flatware.verbose = options[:log]
      configuration = build_rspec_configuration(rspec_args)
      spawn_workers
      formatter = build_formatter(configuration)
      jobs = build_jobs(configuration)
      start_sink(jobs: jobs, workers: workers, formatter: formatter)
    end

    private

    def spawn_workers
      Worker.spawn count: workers, runner: RSpec, sink: options['sink-endpoint']
    end

    def build_rspec_configuration(rspec_args)
      ::RSpec.configuration.tap do |configuration|
        configuration.define_singleton_method(:command) { 'rspec' }
        ::RSpec::Core::ConfigurationOptions.new(rspec_args).configure(configuration)
      end
    end

    def build_jobs(configuration)
      RSpec::JobBuilder.new(configuration, workers: workers).jobs
    end

    def build_formatter(configuration)
      RSpec::Formatters::Console.new(
        configuration.output_stream,
        deprecation_stream: configuration.deprecation_stream
      )
    end
  end
end
