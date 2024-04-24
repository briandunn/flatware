# frozen_string_literal: true

require 'flatware/cli'
require 'flatware/rspec'
require 'flatware/rspec/duration_providers'
require 'flatware/rspec/formatters/console'

module Flatware
  class CLI
    worker_option
    method_option(
      'sink-endpoint',
      type: :string,
      default: 'drbunix:flatware-sink'
    )
    method_option(
      :'duration-provider',
      aliases: '-d',
      type: :string,
      default: :example_statuses,
      desc: 'Duration provider to use. The default option is "example_statuses".'
    )
    desc 'rspec [FLATWARE_OPTS]', 'parallelizes rspec'
    def rspec(*rspec_args)
      duration_provider = RSpec::DurationProviders.lookup(options['duration-provider'])
      jobs = RSpec.extract_jobs_from_args rspec_args, workers: workers, duration_provider: duration_provider

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
