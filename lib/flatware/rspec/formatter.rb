require 'flatware/serialized_exception'
require 'rspec/core/formatters/console_codes'

module Flatware
  module RSpec
    ProgressMessage = Struct.new(:progress)

    class SerializedNotification
      attr_reader :failed_example_count

      def initialize(notification)
        @string = notification.fully_formatted_failed_examples if notification.failed_examples.any?
      end

      def failed_examples
        []
      end

      def fully_formatted(failure_number, colorizer)
        @string.to_s
      end

      def fully_formatted_failed_examples
        @string.to_s
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
        formatted = ""

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

      def initialize(stdout)
        @output = stdout
        @failed_examples = []
      end

      def example_passed(example)
        send_progress :passed
      end

      def example_failed(example)
        send_progress :failed
      end

      def example_pending(example)
        send_progress :pending
      end

      def dump_summary(summary)
        @summary = Summary.new summary.duration, summary.examples.size, summary.failed_examples.size, summary.pending_examples.size
      end

      def dump_failures(notifications)
        @failed_examples << notifications
      end

      def close(*)
        Sink::client.checkpoint Checkpoint.new(summary, failed_examples)
        @failed_examples = []
      end

      private

      def send_progress(status)
        Sink::client.progress ProgressMessage.new status
      end
    end

    ::RSpec::Core::Formatters.register Formatter, :example_passed, :example_failed, :example_pending, :dump_summary, :dump_failures, :close
  end
end
