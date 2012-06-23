require 'cucumber/formatter/console'
module Flatware
  module Cucumber
    class Formatter
      def initialize(*)
      end

      def scenario_name(keyword, name, file_colon_line, source_indent)
        @result = ScenarioResult.new(file_colon_line)
      end

      def after_features(*)
        Sink.push @result
      end

      def after_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background)
        Sink.push @result.add_step_result(status, exception)
      end
    end

    class ScenarioResult
      attr_reader :id, :steps

      def initialize(id)
        @id = id
        @steps = []
      end

      def passed?
        steps.all? &:passed?
      end

      def add_step_result(status, exception)
        StepResult.new(status, exception, self).tap do |result|
          @steps << result
        end
      end
    end

    StepResult = Struct.new(:status, :exception, :scenario) do
      include ::Cucumber::Formatter::Console
      FORMATS = {
        :passed    => '.',
        :failed    => 'F',
        :undefined => 'U',
        :pending   => 'P',
        :skipped   => '-'
      }

      def passed?
        status == :passed
      end

      def progress
        format_string FORMATS[status], status
      end
    end
  end
end
