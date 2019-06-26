# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'flatware/rspec/cli'

module Flatware
  module RSpec
    require 'flatware/rspec/formatters/console'
    require 'flatware/rspec/formatter'
    require 'flatware/rspec/job_builder'

    def self.extract_jobs_from_args(args, workers:)
      JobBuilder.new(args, workers: workers).jobs
    end

    def self.run(job, sink:, **_options)
      runner = ::RSpec::Core::Runner
      def runner.trap_interrupt() end

      args = Array(job)

      ::RSpec.configuration.add_formatter(Flatware::RSpec::Formatter.new(sink))
      runner.run(args, $stderr, $stdout)
    end
  end
end
