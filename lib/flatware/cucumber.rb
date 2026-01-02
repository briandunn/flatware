require 'cucumber'
require 'flatware/cucumber/formatter'
require 'flatware/cucumber/result'
require 'flatware/cucumber/step_result'
require 'flatware/cucumber/formatters/console'
require 'flatware/cucumber/cli'

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
      cucumber_config = ::Cucumber::Configuration.new cli_config
      Config.new cucumber_config, raw_args
    end

    def run(feature_files, options)
      # TODO: This will eventually stop working.  This ensures step definitions are evaluated on each execution
      # by using `load` instead of once per Ruby runtime using `require`.
      #
      # If we use the same runtime object and reconfigure it on each execution here, the wrong feature files will
      # be evaluated since their memoized.  Unfortunately, this means there's no straightforward way to both ensure
      # step definitions are available on every runtime *and* also ensure Cucumber isn't memoizing the feature files
      # to run.
      #
      # For now, the legacy autoloader is the only option to keep everything working properly.
      ::Cucumber.use_legacy_autoloader ||= true

      runtime(Array(feature_files) + options).run!
    end

    def runtime(args)
      ::Cucumber::Runtime.new(configure(args).config)
    end
  end
end
