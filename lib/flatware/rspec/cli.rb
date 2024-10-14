# frozen_string_literal: true

require 'flatware/cli'
require 'flatware/rspec'
require 'flatware/rspec/formatters/console'
require 'flatware/rspec/formatters/fuubar'

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

      Flatware.verbose = options[:log]
      Worker.spawn count: workers, runner: RSpec, sink: options['sink-endpoint']
      start_sink(jobs: jobs, workers: workers, formatter: formatter)
    end

    def formatter
      @formatter ||= begin
        formatter_klass = "Flatware::RSpec::Formatters::#{options[:formatter].capitalize}".constantize

        formatter_klass.new(
          ::RSpec.configuration.output_stream,
          deprecation_stream: ::RSpec.configuration.deprecation_stream
        )
      end
    end
  end
end
