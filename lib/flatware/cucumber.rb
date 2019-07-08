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
      cli_config.parse! args
      cucumber_config = ::Cucumber::Configuration.new cli_config
      Config.new cucumber_config, raw_args
    end

    def run(feature_files, args:, sink:)
      cucumber_config = ::Cucumber::Configuration.new(
        build_cli_config(feature_files, args: args)
      )
      unless cucumber_config.respond_to?(:sink) ||
             cucumber_config.class.prepend(Module.new do
               define_method(:sink) { sink }
             end)
      end

      ::Cucumber::Runtime.new(cucumber_config).run!
    end

    def build_cli_config(feature_files, args:)
      cli_config = ::Cucumber::Cli::Configuration.new($stdout, $stderr)
      cli_config.parse!(
        Array(feature_files) +
        %w[--format Flatware::Cucumber::Formatter] +
        args
      )
      cli_config
    end
  end
end
