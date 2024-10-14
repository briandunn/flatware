require 'flatware/rspec/checkpoint'
require 'rspec/core/formatters/console_codes'
require 'forwardable'

module Flatware
  module RSpec
    class Formatter
      extend Forwardable

      def_delegators :checkpoint, *Checkpoint::EVENTS

      attr_reader :output

      def initialize(stdout)
        @output = stdout
      end

      def start(notification)
        Sink.client.worker_ready notification
      end

      def example_passed(notification)
        send_progress marshaled_progress_notification(notification)
      end

      def example_failed(notification)
        send_progress marshaled_progress_notification(notification)
      end

      def example_pending(notification)
        send_progress marshaled_progress_notification(notification)
      end

      def message(message)
        Sink.client.message message
      end

      def close(*)
        Sink.client.checkpoint checkpoint
        @checkpoint = nil
      end

      private

      def send_progress(notification)
        Sink.client.progress notification
      end

      def checkpoint
        @checkpoint ||= Checkpoint.new
      end

      def marshaled_progress_notification(notification)
        Flatware::RSpec::Marshalable::ExampleNotification.from_rspec(notification)
      end

      ::RSpec::Core::Formatters.register(
        self,
        *Checkpoint::EVENTS,
        :example_passed,
        :example_failed,
        :example_pending,
        :start,
        :message,
        :close
      )
    end
  end
end
