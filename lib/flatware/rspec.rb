require 'rspec/core'
require 'rspec/expectations'
require 'flatware/rspec/cli'

module Flatware
  module RSpec
    require 'flatware/rspec/formatters/console'
    require 'flatware/rspec/formatter'

    def self.extract_jobs_from_args(args, workers:)

      options = ::RSpec::Core::ConfigurationOptions.new(args)
      configuration = ::RSpec::Core::Configuration.new
      def configuration.command() 'rspec' end
      options.configure(configuration)
      configuration.files_to_run.uniq.map do |file|
        Job.new(file, args)
      end
    end

    def self.run(job, options={})
      runner = ::RSpec::Core::Runner
      def runner.trap_interrupt() end

      runner.run(%w[--format Flatware::RSpec::Formatter] + Array(job), $stderr, $stdout)
    end
  end
end
