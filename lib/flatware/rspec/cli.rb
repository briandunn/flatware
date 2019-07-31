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
      default: 'drbunix:sink'
    )
    desc 'rspec [FLATWARE_OPTS]', 'parallelizes rspec'
    def rspec(*rspec_args)
      jobs = RSpec.extract_jobs_from_args rspec_args, workers: workers
      formatter = Flatware::RSpec::Formatters::Console.new($stdout, $stderr)
      Flatware.verbose = options[:log]
      Worker.spawn count: [workers, jobs.size].min, runner: RSpec, sink: options['sink-endpoint']
      start_sink(jobs: jobs,
                 workers: workers,
                 formatter: formatter)
    end
  end
end
