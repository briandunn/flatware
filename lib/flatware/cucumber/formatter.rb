require 'cucumber'
module Flatware
  module Cucumber
    class Formatter
      Checkpoint = Struct.new :steps, :scenarios do
        def failures?
          scenarios.any?(&:failed?)
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

      attr_accessor :sink

      def initialize(config)
        @sink = config.sink
        config.on_event :test_case_finished, &method(:on_test_case_finished)
        config.on_event :test_step_finished, &method(:on_test_step_finished)
        config.on_event :test_run_finished,  &method(:on_test_run_finished)
        config.on_event :step_activated,     &method(:on_step_activated)
        reset
      end

      private

      def reset
        @steps = []
        @scenarios = []
        @matched_steps = Set.new
      end

      attr_reader :steps, :scenarios, :matched_steps

      def on_test_case_finished(event)
        scenarios << Scenario.new(
          event.test_case.name,
          event.test_case.location.to_s,
          event.result.to_sym
        )
      end

      def on_step_activated(event)
        @matched_steps << event.step_match.location.to_s
      end

      def on_test_step_finished(event)
        result = event.result
        return unless really_a_step?(event.test_step) || result.undefined?

        steps << StepResult.new(
          result.to_sym,
          result.failed? && result.exception
        )
        sink.progress Result.new result.to_sym
      end

      def on_test_run_finished(*)
        sink.checkpoint Checkpoint.new steps, scenarios
        reset
      end

      def really_a_step?(step)
        matched_steps.include?(step.action_location.to_s)
      end
    end
  end
end
