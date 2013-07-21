require 'flatware/checkpoint'
require 'flatware/scenario_decorator'
module Flatware
  module Cucumber
    class Formatter
      def initialize(step_mother, *)
        @collector = Collector.new step_mother
      end

      def after_features(*)
        Sink.push collector.checkpoint
      end

      def after_step_result(_, _, _, status, *)
        send_progress(status)
      end

      def table_cell_value(_, status)
        send_progress(status) if status
      end

      private
      attr_reader :collector

      def send_progress(status)
        Sink.push Result.status status
      end

      class Collector
        attr_reader :step_mother
        def initialize(step_mother)
          @step_mother = step_mother
          snapshot
        end

        def checkpoint
          Checkpoint.new(step_mother.steps - @ran_steps, decorate_scenarios(step_mother.scenarios - @ran_scenarios)).tap do
            snapshot
          end
        end

        private

        def snapshot
          @ran_steps = step_mother.steps.dup
          @ran_scenarios = step_mother.scenarios.dup
        end

        def decorate_scenarios(scenarios)
          scenarios.map { |scenario| ScenarioDecorator.new(scenario) }
        end
      end
    end

  end
end
