require 'forwardable'
module Flatware
  module Cucumber
    class ScenarioDecorator
      extend Forwardable
      def_delegators :scenario, :name

      attr_reader :status

      def initialize(scenario)
        @scenario, @status = scenario, scenario.status
        @scenario = scenario.scenario_outline if example_row?
      end

      def exception
        if status == :failed
          if scenario.respond_to?(:exception)
            scenario.exception
          else
            e = StandardError.new("Unknown Exception")
            e.set_backtrace []
            e
          end
        end
      end

      def file_colon_line
        scenario.location.to_s
      end

      private

      attr_reader :scenario

      def example_row?
        scenario.respond_to? :scenario_outline
      end
    end
  end
end
