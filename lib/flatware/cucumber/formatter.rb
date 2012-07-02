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

    class Formatter
      def initialize(*)
      end

      def scenario_name(keyword, name, file_colon_line, source_indent)
        push_scenario_result
        @result = ScenarioResult.new(file_colon_line)
      end

      def after_features(*)
        push_scenario_result
      end

      def after_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background)
        Sink.push StepResult.add(status, exception)
      end

      private

      def push_scenario_result
        if @result
          @result.steps = StepResult.all
          Sink.push @result
          StepResult.all.clear
          @result = nil
        end
      end
    end

    class ScenarioResult
      attr_reader :id
      attr_accessor :steps

      def initialize(id)
        @id = id.split(':').first
        @steps = []
      end

      def passed?
        steps.all? &:passed?
      end

      def status
        passed? ? :passed : :failed
      end
    end

    class Summary
      include ::Cucumber::Formatter::Console
      attr_reader :scenarios, :io, :steps

      def initialize(scenarios, steps, io=StringIO.new)
        @io = io
        @scenarios = scenarios
        @steps = steps
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
        io.puts "#{pluralize 'step',steps.size} (#{count_summary steps})"
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

    class StepResult
      include ::Cucumber::Formatter::Console
      attr_reader :status, :exception

      def initialize(status, exception)
        @status, @exception = status, serialized(exception)
      end

      def passed?
        status == :passed
      end

      def progress
        format_string FORMATS[status], status
      end

      private
      def serialized(e)
        SerializedException.new(e.class, e.message, e.backtrace) if e
      end

      class << self
        def add(status, exception)
          new(status, exception).tap do |result|
            all << result
          end
        end

        def all
          @all ||= []
        end
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
