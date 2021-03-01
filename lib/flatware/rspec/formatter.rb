require 'flatware/rspec/checkpoint'
require 'rspec/core/formatters/console_codes'
require 'forwardable'

module Flatware
  module RSpec
    ProgressMessage = Struct.new(:progress)

    class Formatter
      extend Forwardable

      def_delegators :@checkpoint, *Checkpoint::EVENTS

      attr_reader :output

      def initialize(stdout)
        @output = stdout
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

      def start_dump(*)
        @checkpoint = Checkpoint.new
      end

      def close(*)
        Sink.client.checkpoint @checkpoint
        @checkpoint = nil
      end

      private

      def send_progress(status)
        Sink.client.progress ProgressMessage.new status
      end
    end

    ::RSpec::Core::Formatters.register(
      Formatter,
      *Checkpoint::EVENTS,
      :example_passed,
      :example_failed,
      :example_pending,
      :start_dump,
      :close
    )
  end
end
