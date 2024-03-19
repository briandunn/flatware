require 'flatware/rspec/checkpoint'
require 'rspec/core/formatters/console_codes'
require 'forwardable'

module Flatware
  module RSpec
    ProgressMessage = Struct.new(:progress, :location)

    class Formatter
      extend Forwardable

      def_delegators :checkpoint, *Checkpoint::EVENTS

      attr_reader :output, :all_examples

      def initialize(stdout)
        @output = stdout
      end

      def example_passed(notification)
        send_progress notification, :passed
      end

      def example_failed(notification)
        send_progress notification, :failed
      end

      def example_pending(notification)
        send_progress notification, :pending
      end

      def message(message)
        Sink.client.message message
      end

      def close(*)
        Sink.client.checkpoint checkpoint
        @checkpoint = nil
      end

      def start(_notification)
        Sink.client.started Set.new(::RSpec.world.all_examples.map(&:location))
      end

      private

      def send_progress(notification, status)
        Sink.client.progress ProgressMessage.new(status, notification.example.location)
      end

      def checkpoint
        @checkpoint ||= Checkpoint.new
      end

      ::RSpec::Core::Formatters.register(
        self,
        *Checkpoint::EVENTS,
        :example_passed,
        :example_failed,
        :example_pending,
        :message,
        :start,
        :close
      )
    end
  end
end
