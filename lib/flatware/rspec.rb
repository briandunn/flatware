require 'rspec/core'
require 'rspec/expectations'
require 'flatware/formatters/rspec/console'
require 'flatware/rspec/formatter'
require 'flatware/rspec/summary'

module Flatware
  module RSpec
    def self.extract_jobs_from_args(args)
      options = ::RSpec::Core::ConfigurationOptions.new(args)
      configuration = ::RSpec::Core::Configuration.new
      def configuration.command; 'rspec' end
      options.configure(configuration)
      configuration.files_to_run.uniq.map do |arg|
        Job.new(arg, args)
      end
    end

    def self.run(job, options={})
      ::RSpec::Core::Runner.run(%w[--format Flatware::RSpec::Formatter] + [job], $stderr, $stdout)
      ::RSpec.clear_examples
    end
  end
end
