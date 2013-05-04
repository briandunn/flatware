require 'cucumber'
require_relative 'cucumber/runtime'
module Flatware

  class JobCue
    attr_reader :jobs

    def initialize(jobs)
      @jobs = jobs
    end

    def empty?
      @jobs.empty?
    end

    def remaining_work
      jobs
    end

    def pop
      @jobs.pop
    end
  end

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

    attr_reader :job_cue

    def extract_jobs_from_args(args=[], out_stream=$stdout, error_stream=$stderr)
      raw_args = args.dup
      config = ::Cucumber::Cli::Configuration.new(out_stream, error_stream)
      config.parse! args
      options = raw_args - args
      @job_cue = JobCue.new(config.feature_files.map { |file| Job.new file, options })
    end

    def run(feature_files=[], options=[])
      runtime.run feature_files, options
    end

    def runtime
      @runtime ||= Runtime.new
    end
  end
end
