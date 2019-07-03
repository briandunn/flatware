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

    def run(job, sink:, **)
      options = ::RSpec::Core::ConfigurationOptions.new(Array(job))
      runner = ::RSpec::Core::Runner.new(options)
      runner.configuration.add_formatter(Formatter.new(sink))
      runner.run($stderr, $stdout)
    end
  end
end
