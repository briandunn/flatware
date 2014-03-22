require 'forwardable'
module Flatware
  module Cucumber
    class ScenarioDecorator
      extend Forwardable
      def_delegators :scenario, :name, :file_colon_line

      attr_reader :status, :exception

      def initialize(scenario)
        @scenario, @status, @exception = scenario, scenario.status, scenario.exception
        @scenario, @exception = scenario.scenario_outline, scenario.exception if example_row?
      end

      private

      attr_reader :scenario

      def example_row?
        scenario.respond_to? :scenario_outline
      end
    end
  end
end
