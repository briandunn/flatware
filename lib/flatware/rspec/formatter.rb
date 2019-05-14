# frozen_string_literal: true

require 'rspec/core'
require 'flatware/rspec/checkpoint'
require 'flatware/rspec/summary'
require 'flatware/sink'
require 'rspec/core/formatters/console_codes'
require 'rspec/core/example_status_persister'

module Flatware
  module RSpec
    ProgressMessage = Struct.new(:progress)

    # override this check.
    # RSpec version assumes runner has loaded all spec files.
    # But our runner has only loaded some.
    ::RSpec::Core::ExampleStatusMerger.prepend(Module.new do
      def example_must_no_longer_exist?(ex_id)
        # Obviously, it exists if it was loaded for this spec run...
        return false if @this_run.key?(ex_id)

        spec_file = spec_file_from(ex_id)

        # The example may still exist as long as the file exists...
        !@file_exists_cache[spec_file]
      end
    end)

    class Formatter
      attr_reader :summary, :output

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

      def dump_summary(summary)
        @summary = Summary.from_notification(summary)
      end

      def dump_failures(failure_notification)
        @failure_notification = failure_notification
      end

      def close(*)
        Sink.client.checkpoint Checkpoint.new(summary, @failure_notification)
        @failure_notification = nil
      end

      private

      def send_progress(status)
        Sink.client.progress ProgressMessage.new status
      end
    end

    ::RSpec::Core::Formatters.register Formatter, :example_passed, :example_failed, :example_pending, :dump_summary, :dump_failures, :close
  end
end
