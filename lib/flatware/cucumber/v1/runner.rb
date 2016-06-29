require 'flatware/cucumber/runtime'

module Flatware
  module Cucumber
    module V1
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

        def configure(args, out_stream, error_stream)
          raw_args = args.dup
          config = ::Cucumber::Cli::Configuration.new(out_stream, error_stream)
          config.parse! args

          Config.new config, raw_args
        end


        def run(feature_files, options)
          runtime.run feature_files, options
        end

        def runtime
          @runtime ||= Runtime.new
        end
      end
    end
  end
end
