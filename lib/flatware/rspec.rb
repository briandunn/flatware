require 'rspec/core'
require 'flatware/rspec/formatter'
require 'flatware/formatters/rspec/console'

module Flatware
  module RSpec
    def self.extract_jobs_from_args(args)
      options = ::RSpec::Core::ConfigurationOptions.new(args)
      options.parse_options
      configuration = ::RSpec::Core::Configuration.new
      def configuration.command; 'rspec' end
      options.configure(configuration)
      configuration.files_to_run.uniq.map do |arg|
        Job.new(arg, [])
      end
    end

    def self.run(job, options={})
      ::RSpec::Core::CommandLine.new(%w[--format Flatware::RSpec::Formatter] + [job]).run($stderr, $stdout)
      ::RSpec.reset
    end
  end
end
