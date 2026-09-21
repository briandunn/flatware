require 'cucumber'
require 'flatware/cucumber/formatter'
require 'flatware/cucumber/result'
require 'flatware/cucumber/step_result'
require 'flatware/cucumber/formatters/console'
require 'flatware/cucumber/cli'
require 'flatware/cucumber/runtime'

module Flatware
  module Cucumber
    class Config
      attr_reader :config, :args

      def initialize(cucumber_config, args)
        @config = cucumber_config
        @args = args
      end

      def feature_dir
        @config.feature_dirs.first
      end

      def jobs
        feature_files.map { |file| Job.new file, args }.to_a
      end

      private

      def feature_files
        config.feature_files - config.feature_dirs
      end
    end

    module_function

    def configure(args, out_stream = $stdout, error_stream = $stderr)
      raw_args = args.dup
      cli_config = ::Cucumber::Cli::Configuration.new(out_stream, error_stream)
      cli_config.parse! args + %w[--format Flatware::Cucumber::Formatter --publish-quiet]
      cucumber_config = ::Cucumber::Configuration.new cli_config.to_hash.merge(event_bus: event_bus)
      Config.new cucumber_config, raw_args
    end

    # Cucumber loads support code with `require`, so step definitions can only be registered once
    # per process. Keep one runtime per worker and reconfigure it for each job. The runtime also
    # memoizes its formatters against the first configuration's event bus, so every job's
    # configuration must share that bus or later results never reach the formatter.
    def run(feature_files, options)
      config = configure(Array(feature_files) + options).config
      runtime.configure config
      runtime.run!
    end

    def runtime
      @runtime ||= Runtime.new
    end

    def event_bus
      @event_bus ||= ::Cucumber::Events.make_event_bus
    end
  end
end
