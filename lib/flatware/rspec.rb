require 'rspec/core'
require 'rspec/expectations'
require 'flatware/formatters/rspec/console'
require 'flatware/rspec/formatter'

module Flatware
  module RSpec
    def self.extract_jobs_from_args(args, workers:)

      options = ::RSpec::Core::ConfigurationOptions.new(args)
      configuration = ::RSpec::Core::Configuration.new
      def configuration.command() 'rspec' end
      options.configure(configuration)
      configuration.files_to_run.uniq.group_by.with_index do |_,i|
        i % workers
      end.values.map do |files|
        Job.new(files, args)
      end
    end

    def self.run(job, options={})
      runner = ::RSpec::Core::Runner
      def runner.trap_interrupt() end

      runner.run(%w[--format Flatware::RSpec::Formatter] + Array(job), $stderr, $stdout)
    end
  end
end
