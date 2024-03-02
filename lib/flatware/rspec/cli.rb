# frozen_string_literal: true

require 'flatware/cli'
require 'flatware/configuration'
require 'flatware/rspec'
require 'flatware/rspec/formatters/console'

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
      # the file hasn't been evaluated yet, because `-r` is handled by rspec
      # and the rspec configuration is loaded by `extract_jobs_from_args`
      Flatware.configuration.before_fork.call

      jobs = RSpec.extract_jobs_from_args rspec_args, workers: workers

      formatter = Flatware::RSpec::Formatters::Console.new(
        ::RSpec.configuration.output_stream,
        deprecation_stream: ::RSpec.configuration.deprecation_stream
      )

      Flatware.verbose = options[:log]
      Worker.spawn count: workers, runner: RSpec, sink: options['sink-endpoint']
      start_sink(jobs: jobs, workers: workers, formatter: formatter)
    end
  end
end
