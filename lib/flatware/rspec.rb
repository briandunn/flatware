# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'flatware/rspec/cli'

module Flatware
  module RSpec
    require 'flatware/rspec/formatter'
    require 'flatware/rspec/job_builder'

    module_function

    def extract_jobs_from_args(args, workers:)
      JobBuilder.new(args, workers: workers).jobs
    end

    def run(job, _options = {})
      runner = ::RSpec::Core::Runner
      def runner.trap_interrupt() end

      ::RSpec.reset
      ::RSpec.configuration.deprecation_stream = StringIO.new
      ::RSpec.configuration.output_stream = StringIO.new
      ::RSpec.configuration.add_formatter(Flatware::RSpec::Formatter)

      runner.run(Array(job), $stderr, $stdout)
    end
  end
end
