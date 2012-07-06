require 'cucumber/formatter/console'
module Flatware
  module Cucumber

    FORMATS = {
      :passed    => '.',
      :failed    => 'F',
      :undefined => 'U',
      :pending   => 'P',
      :skipped   => '-'
    }

    STATUSES = FORMATS.keys

    class Result
      attr_reader :progress, :steps

      def initialize(progress, steps=nil)
        @progress, @steps = progress, steps || []
      end

      class << self
        def step(*args)
          step = StepResult.new *args
          new step.progress, [step]
        end
      end
    end

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
        result = if scenario_outline?
          Result.new ProgressString.format status
        else
          Result.step status, exception, @current_scenario
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
          @step_collector.stop(table_row)
          Sink.push Result.new @step_collector.progress, @step_collector.steps
        end
      end

      def table_cell_value(_, status)
        Sink.push Result.new ProgressString.format status if example_cell? status
      end

      private

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

      attr_reader :step_mother

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
    end

    class ScenarioResult
      attr_reader :id, :steps

      def initialize(id, steps=[])
        @id = id
        @steps = steps
      end

      def status
        first(:failed) || first(:undefined) || :passed
      end

      private

      def first(status)
        statuses.detect {|s| s == status}
      end

      def statuses
        steps.map &:status
      end
    end

    class Summary
      include ::Cucumber::Formatter::Console
      attr_reader :io, :steps

      def initialize(steps, io=StringIO.new)
        @io = io
        @steps = steps
      end

      def scenarios
        @scenarios ||= steps.group_by(&:scenario_id).map do |scenario, steps|
          ScenarioResult.new(scenario, steps)
        end
      end

      def summarize
        2.times { io.puts }
        print_steps :failed
        print_scenario_counts
        print_step_counts
      end

      private

      def print_steps(status)
        print_elements steps.select(&with_status(status)), status, 'steps'
      end

      def print_scenario_counts
        io.puts "#{pluralize 'scenario', scenarios.size} (#{count_summary scenarios})"
      end

      def print_step_counts
        io.puts "#{pluralize 'step', steps.size} (#{count_summary steps})"
      end

      def pluralize(word, number)
        "#{number} #{number == 1 ? word : word + 's'}"
      end

      def with_status(status)
        proc {|r| r.status == status}
      end

      def count_summary(results)
        STATUSES.map do |status|
          count = results.select(&with_status(status)).size
          format_string "#{count} #{status}", status if count > 0
        end.compact.join ", "
      end

      def count(status)
        completed_scenarios.select {|scenario| scenario.status == status}.count
      end
    end

    class ProgressString
      extend ::Cucumber::Formatter::Console
      def self.format(status)
        format_string FORMATS[status], status
      end
    end

    class StepResult
      attr_reader :status, :exception, :scenario_id

      def initialize(status, exception, scenario_id=nil)
        @status, @exception, @scenario_id = status, serialized(exception), scenario_id
      end

      def passed?
        status == :passed
      end

      def failed?
        status == :failed
      end

      def progress
        ProgressString.format(status)
      end

      private
      def serialized(e)
        SerializedException.new(e.class, e.message, e.backtrace) if e
      end
    end

    class SerializedException
      attr_reader :class, :message, :backtrace
      def initialize(klass, message, backtrace)
        @class, @message, @backtrace = serialized(klass), message, backtrace
      end

      private
      def serialized(klass)
        SerializedClass.new(klass.to_s)
      end
    end

    class SerializedClass
      attr_reader :name
      alias to_s name
      def initialize(name); @name = name end
    end
  end
end
