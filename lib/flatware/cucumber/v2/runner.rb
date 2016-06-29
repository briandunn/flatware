require 'cucumber/cli/main'
module Flatware
  module Cucumber::V2
    class Config
      attr_reader :config, :args
      def initialize(cucumber_config, args)
        @config, @args = cucumber_config, args
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

    module Runner
      extend self

      def configure(args, out_stream=$stdout, error_stream=$stderr)
        raw_args = args.dup
        cli_config = ::Cucumber::Cli::Configuration.new(out_stream, error_stream)
        cli_config.parse! args + %w[--format Flatware::Cucumber::Formatter]
        cucumber_config = ::Cucumber::Configuration.new cli_config
        Config.new cucumber_config, raw_args
      end


      def run(feature_files, options)
        runtime(Array(feature_files) + options).run!
      end

      def runtime(args)
        @runtime ||= ::Cucumber::Runtime.new
        @runtime.support_code.ruby.step_definitions.clear
        @runtime.configure configure(args).config
        @runtime
      end
    end
  end
end
