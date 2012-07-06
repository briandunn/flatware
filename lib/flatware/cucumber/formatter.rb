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
      def initialize(*)
      end

      def scenario_name(keyword, name, file_colon_line, source_indent)
        @current_scenario = file_colon_line
      end

      def after_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background)
        Sink.push Result.step status, exception, @current_scenario
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
