require 'flatware/serialized_exception'

module Flatware
  module RSpec
    ProgressMessage = Struct.new(:progress)

    class SerializedExampleGroup
      attr_reader :example_group, :parent_groups, :metadata

      def initialize(example_group)
        @example_group = example_group.to_s
        @metadata = Hash[metadata.to_a].except(:block)
        @parent_groups = serialize_parent_groups(example_group.parent_groups)
      end

      def serialize_parent_groups(example_groups)
        example_groups.map do |group|
          self.class.new(group) unless group.to_s == example_group
        end.compact
      end
    end

    class SerializedNotification
      attr_reader :exception, :example
      def initialize(notification)
        @exception = SerializedException.from notification.exception
        @example = SerializedExample.new notification.example
      end

      def fully_formatted(failure_number, colorizer=::RSpec::Core::Formatters::ConsoleCodes)
        exception_presenter.fully_formatted(failure_number, colorizer)
      end

      private

      def exception_presenter
        ::RSpec::Core::Formatters::ExceptionPresenter.new(exception, example)
      end
    end

    class SerializedExample
      attr_reader :metadata, :execution_result, :full_description
      def initialize(example)
        @metadata = example.metadata.reject {|k| %i[block example_group described_class].include? k }
        @full_description = example.full_description
        @execution_result = example.execution_result
        @execution_result.exception = SerializedException.from @execution_result.exception
      end
    end

    class Checkpoint
      attr_reader :summary, :failure_notifications

      def initialize(summary, failure_notifications)
        @summary, @failure_notifications = summary, failure_notifications.map(&method(:serialize_notification))
      end

      def +(other)
        self.class.new summary + other.summary, failure_notifications + other.failure_notifications
      end

      def failures?
        summary.failure_count > 0
      end

      def fully_formatted_failed_examples(colorizer=::RSpec::Core::Formatters::ConsoleCodes)
        formatted = "\nFailures:\n"

        failure_notifications.each_with_index do |failure, index|
          formatted << failure.fully_formatted(index.next, colorizer)
        end

        formatted
      end


      private

      def serialize_notification(notification)
        SerializedNotification.new notification
      end
    end

    class Formatter
      attr_reader :summary, :output, :failed_examples

      def initialize(stdout=nil)
        @output = stdout
        @failed_examples = []
      end

      def example_passed(example)
        send_progress :passed
      end

      def example_failed(example)
        @failed_examples << example
        send_progress :failed
      end

      def example_pending(example)
        send_progress :pending
      end

      def dump_summary(summary)
        @summary = Summary.new summary.duration, summary.examples.size, summary.failed_examples.size, summary.pending_examples.size
      end

      def close(*)
        Sink::client.checkpoint Checkpoint.new(summary, failed_examples)
      end

      private

      def send_progress(status)
        Sink::client.progress ProgressMessage.new status
      end
    end

    ::RSpec::Core::Formatters.register Formatter, :example_passed, :example_failed, :example_pending, :dump_summary, :close
  end
end
