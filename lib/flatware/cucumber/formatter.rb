require 'cucumber'
require 'flatware/sink'
require 'ostruct'
module Flatware
  module Cucumber
    class Formatter
      Checkpoint = Struct.new :steps, :scenarios do
        def failures?
          scenarios.any? &:failed?
        end
      end

      Scenario = Struct.new :name, :file_colon_line, :status do
        def failed?
          status == :failed
        end

        def failed_outside_step?
          false
        end
      end

      def initialize(config)
        @fail_fast = config.to_hash[:fail_fast]
        config.on_event :after_test_case,  &method(:on_after_test_case)
        config.on_event :after_test_step,  &method(:on_after_test_step)
        config.on_event :finished_testing, &method(:on_finished_testing)
        config.on_event :step_match,       &method(:on_step_match)
        reset
      end

      private

      def fail_fast?
        !!@fail_fast
      end

      def reset
        @steps = []
        @scenarios = []
        @matched_steps = Set.new
      end

      attr_reader :steps, :scenarios, :matched_steps

      def on_after_test_case(event)
        scenarios << Scenario.new(event.test_case.name, event.test_case.location.to_s, event.result.to_sym)
        ::Cucumber.wants_to_quit = true if fail_fast? and not event.result.ok?
      end

      def on_step_match(event)
        @matched_steps << event.step_match.location.to_s
      end

      def on_after_test_step(event)
        if really_a_step?(event.test_step) or event.result.undefined?
          steps << StepResult.new(event.result.to_sym, event.result.failed? && event.result.exception)
          Sink::client.progress Result.new event.result.to_sym
        end
      end

      def on_finished_testing(*)
        Sink::client.checkpoint Checkpoint.new steps, scenarios
        reset
      end

      def really_a_step?(step)
        matched_steps.include?(step.action_location.to_s)
      end
    end
  end
end
