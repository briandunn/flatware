require 'cucumber'
require 'flatware/sink'
require 'ostruct'
module Flatware
  module Cucumber
    class Formatter
      Checkpoint = Struct.new :scenarios do
        def steps
          scenarios.flat_map(&:steps)
        end

        def failures?
          scenarios.any? &:failed?
        end
      end

      Scenario = Struct.new :name, :file_colon_line do
        attr_accessor :status

        def steps
          @steps ||= []
        end

        def failed?
          status == :failed
        end

        def failed_outside_step?
          false
        end

        def self.from_test_case(test_case)
          new test_case.name, test_case.location.to_s
        end
      end

      def initialize(config)
        config.on_event :after_test_case,  &method(:on_after_test_case)
        config.on_event :after_test_step,  &method(:on_after_test_step)
        config.on_event :finished_testing, &method(:on_finished_testing)
        config.on_event :step_match,       &method(:on_step_match)
        reset
      end

      private

      def reset
        @steps = []
        @scenarios = []
        @matched_steps = Set.new
        @current_scenario = nil
      end

      attr_reader :steps, :scenarios, :matched_steps, :current_scenario

      def on_after_test_case(event)
        scenario = current_scenario || Scenario.from_test_case(event.test_case)
        scenario.status = event.result.to_sym
        scenarios << current_scenario
        @current_scenario = nil
      end

      def on_step_match(event)
        @matched_steps << event.step_match.location.to_s
      end

      def on_after_test_step(event)
        if really_a_step?(event.test_step) or event.result.undefined?
          @current_scenario ||= Scenario.from_test_case event.test_case
          result = event.result
          current_scenario.steps << StepResult.new(result.to_sym, result.failed? && result.exception)
          Sink::client.progress Result.new result.to_sym
        end
      end

      def on_finished_testing(*)
        Sink::client.checkpoint Checkpoint.new scenarios
        reset
      end

      def really_a_step?(step)
        matched_steps.include?(step.action_location.to_s)
      end
    end
  end
end
