# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'flatware/rspec/patch_configuration'
require 'flatware/rspec/cli'

module Flatware
  module RSpec
    require 'flatware/rspec/formatter'
    require 'flatware/rspec/job_builder'

    module_function

    def extract_jobs_from_args(args, workers:)
      JobBuilder.new(args, workers: workers).jobs
    end

    def run(files, sink:, args:)
      options = ::RSpec::Core::ConfigurationOptions.new(Array(files) + args)
      configuration = ::RSpec.configuration
      configuration.filter_gems_from_backtrace 'flatware'
      options.configure(configuration)
      configuration.add_formatter(Formatter.new(sink))

      runner = ::RSpec::Core::Runner.new(options)
      runner.run($stderr, $stdout)
    end
  end
end
