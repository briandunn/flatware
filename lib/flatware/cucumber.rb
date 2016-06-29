require 'cucumber'
require 'flatware/cucumber/checkpoint'
require 'flatware/cucumber/formatter'
require 'flatware/cucumber/result'
require 'flatware/cucumber/scenario_decorator'
require 'flatware/cucumber/scenario_result'
require 'flatware/cucumber/step_result'
require 'flatware/formatters/cucumber/console'

module Flatware
  module Cucumber
    extend self

    def configure(args=[], out_stream=$stdout, error_stream=$stderr)
      runner.configure(args, out_stream, error_stream)

    end

    def run(feature_files=[], options=[])
      runner.run feature_files, options
    end

    def runner
      @runner ||= if Gem.loaded_specs['cucumber'].version < Gem::Version.new('2.0.0')
        require 'flatware/cucumber/v1/runner'
        V1
      else
        require 'flatware/cucumber/v2/runner'
        V2
      end::Runner
    end
  end
end
