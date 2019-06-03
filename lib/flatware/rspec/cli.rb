# frozen_string_literal: true

require 'flatware/cli'

module Flatware
  class CLI
    runner_options
    desc 'rspec [FLATWARE_OPTS]', 'parallelizes rspec'
    def rspec(*rspec_args)
      jobs = RSpec.extract_jobs_from_args rspec_args, workers: workers
      Flatware.verbose = options[:log]
      spawn_workers(runner: RSpec)
      start_sink jobs: jobs, workers: workers, formatter: Flatware::RSpec::Formatters::Console.new($stdout, $stderr)
    end
  end
end
