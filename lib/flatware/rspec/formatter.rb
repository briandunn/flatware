module Flatware
  module RSpec
    ProgressMessage = Struct.new(:progress)
    Summary = Struct.new(:duration, :example_count, :failure_count, :pending_count)
    Checkpoint = Struct.new(:summary) do
      def failures?
        summary.failure_count > 0
      end
    end
    class Formatter
      attr_reader :summary

      def initialize(stdout=nil)
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

      def dump_summary(duration, example_count, failure_count, pending_count)
        @summary = Summary.new duration, example_count, failure_count, pending_count
      end

      def close
        Sink::client.checkpoint Checkpoint.new(summary)
      end

      private

      def send_progress(status)
        Sink::client.progress ProgressMessage.new status
      end
    end
  end
end
