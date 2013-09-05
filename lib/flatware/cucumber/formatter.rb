require 'flatware/checkpoint'
require 'flatware/scenario_decorator'
require 'flatware/sink'
require 'ostruct'
module Flatware
  module Cucumber
    class Formatter

      def initialize(step_mother, *)
        @collector = Collector.new step_mother
        @scenarios = []
        @in_a_step = false
      end

      def after_features(*)
        checkpoint = collector.checkpoint
        scenarios.select(&:exception).map(&:file_colon_line).each do |file_colon_line|
          scenario = checkpoint.scenarios.detect do |scenario|
            scenario.file_colon_line == file_colon_line
          end
          scenario.failed_outside_step!(file_colon_line) if scenario
        end
        Sink::client.checkpoint checkpoint
      end

      def after_step_result(_, _, _, status, *)
        send_progress(status)
      end

      def table_cell_value(_, status)
        send_progress(status) if status
      end

      def exception(exception, status)
        unless @in_a_step
          current_scenario.exception = exception
          send_progress(status)
        end
      end

      def respond_to?(x)
        super
      end

      def before_outline_table(*)
        @in_examples = true
      end

      def after_outline_table(*)
        @in_examples = false
      end

      def before_table_cell(*)
        @in_a_step = @in_examples
      end

      def after_table_cell(*)
        @in_a_step = ! @in_examples
      end

      def after_table_row(table_row)
        exception(table_row.exception, :failed) if table_row.exception
      end

      def before_step(*)
        @in_a_step = true
      end

      def after_step(*)
        @in_a_step = false
      end

      def scenario_name(_, name, file_colon_line, *)
        scenarios.push OpenStruct.new file_colon_line: file_colon_line, name: name
      end

      private
      attr_reader :collector, :scenarios

      def current_scenario
        scenarios.last
      end

      def send_progress(status)
        Sink::client.progress Result.new status
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
