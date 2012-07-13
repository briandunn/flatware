require 'cucumber'
require_relative 'cucumber/runtime'
module Flatware
  module Cucumber
    autoload :Formatter, 'flatware/cucumber/formatter'
    autoload :ProgressString, 'flatware/cucumber/formatter'

    FORMATS = {
      :passed    => '.',
      :failed    => 'F',
      :undefined => 'U',
      :pending   => 'P',
      :skipped   => '-'
    }

    STATUSES = FORMATS.keys

    extend self

    attr_reader :jobs

    def extract_jobs_from_args(args=[], out_stream=$stdout, error_stream=$stderr)
      config = ::Cucumber::Cli::Configuration.new(out_stream, error_stream)
      config.parse! args
      @jobs = config.feature_files.map { |file| Job.new file }
    end

    def run(feature_files=[], options=[])
      runtime.run feature_files, options
    end

    def runtime
      @runtime ||= Runtime.new
    end
  end
end
