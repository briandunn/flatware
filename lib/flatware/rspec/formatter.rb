require 'flatware/rspec/checkpoint'
require 'flatware/rspec/summary'
require 'rspec/core/formatters/console_codes'

module Flatware
  module RSpec
    ProgressMessage = Struct.new(:progress)

    class Formatter
      attr_reader :summary, :sink

      def initialize(sink)
        @sink = sink
      end

      def example_passed(_example)
        send_progress :passed
      end

      def example_failed(_example)
        send_progress :failed
      end

      def example_pending(_example)
        send_progress :pending
      end

      def dump_summary(summary)
        @summary = Summary.from_notification(summary)
      end

      def dump_failures(failure_notification)
        @failure_notification = failure_notification
      end

      def close(*)
        sink.checkpoint Checkpoint.new(summary, @failure_notification)
        @failure_notification = nil
      end

      private

      def send_progress(status)
        sink.progress ProgressMessage.new status
      end
    end

    ::RSpec::Core::Formatters.register(
      Formatter,
      :example_passed,
      :example_failed,
      :example_pending,
      :dump_summary,
      :dump_failures,
      :close
    )
  end
end
