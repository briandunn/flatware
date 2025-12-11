# frozen_string_literal: true

require 'flatware/cli'
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
      jobs = RSpec.extract_jobs_from_args rspec_args, workers: workers

      formatter = Flatware::RSpec::Formatters::Console.new(
        ::RSpec.configuration.output_stream,
        deprecation_stream: ::RSpec.configuration.deprecation_stream
      )

      Flatware.verbose = options[:log]

      spawn_count = worker_spawn_count(jobs)
      Worker.spawn(count: spawn_count, runner: RSpec, sink: options['sink-endpoint'])
      start_sink(jobs: jobs, workers: spawn_count, formatter: formatter)
    end
  end
end
