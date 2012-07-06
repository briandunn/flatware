require 'cucumber/formatter/console'
module Flatware
  module Cucumber
    class Formatter
      def initialize(step_mother, *)
        @step_mother = step_mother
      end

      def scenario_name(keyword, name, file_colon_line, source_indent)
        @current_scenario = file_colon_line
      end

      def before_feature_element(feature_element)
        case feature_element
        when ::Cucumber::Ast::ScenarioOutline
          @outline_steps = feature_element
        end
      end

      def after_feature_element(feature_element)
        @outline_steps = nil
      end

      def after_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background)
        result = if status_only? background
          Result.status status
        else
          Result.step status, exception, current_scenario
        end

        Sink.push result
      end

      def before_outline_table(outline_table)
        @outline_table = outline_table
      end

      def after_outline_table(outline_table)
        @outline_table = nil
      end

      def before_table_row(table_row)
        if example_row? table_row
          @step_collector = StepCollector.new(step_mother)
        end
      end

      def after_table_row(table_row)
        if example_row? table_row
          step_collector.stop table_row
          Sink.push Result.new step_collector.progress, step_collector.steps
        end
      end

      def table_cell_value(_, status)
        Sink.push Result.status status if example_cell? status
      end

      private

      attr_reader :step_mother, :step_collector, :current_scenario

      def status_only?(background)
        scenario_outline? or (background and not current_scenario)
      end

      def scenario_outline?
        !!@outline_steps
      end

      def example_row?(table_row)
        outline_table? and not table_header_row? table_row
      end

      def example_cell?(status)
        outline_table? and not table_header_cell? status
      end

      def table_header_cell?(status)
        status == :skipped_param
      end

      def outline_table?
        !!@outline_table
      end

      def table_header_row?(table_row)
        table_row.failed?
      rescue ::Cucumber::Ast::OutlineTable::ExampleRow::InvalidForHeaderRowError
        true
      else
        false
      end

      class StepCollector
        attr_reader :step_mother
        def initialize(step_mother)
          @step_mother = step_mother
          snapshot_steps
        end

        def stop(table_row)
          @scenario_id = extract_scenario(table_row)
          @example_row_steps = step_mother.steps - ran_steps
        end

        def steps
          example_row_steps or raise('stop collecting first')
          example_row_steps.map do |step|
            StepResult.new(step.status, step.exception, scenario_id)
          end
        end

        def progress
          ''
        end

        private

        attr_reader :example_row_steps, :scenario_id, :ran_steps

        def extract_scenario(table_row)
          table_row.scenario_outline.file_colon_line(table_row.line)
        end

        def snapshot_steps
          @ran_steps = step_mother.steps.dup
        end
      end
    end

    class ProgressString
      extend ::Cucumber::Formatter::Console
      def self.format(status)
        return '' unless status
        format_string FORMATS[status], status
      end
    end
  end
end
