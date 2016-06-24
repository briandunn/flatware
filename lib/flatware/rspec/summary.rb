require 'rspec/core/notifications'
module Flatware
  module RSpec
    Summary = Struct.new(:duration, :examples, :failed_examples, :pending_examples, :load_time)

    class Example
      attr_reader :location_rerun_argument, :full_description
      def initialize(rspec_example)
        @full_description        = rspec_example.full_description
        @location_rerun_argument = rspec_example.location_rerun_argument
      end
    end

    class Summary
      def +(other)
        self.class.new duration + other.duration,
          examples + other.examples,
          failed_examples + other.failed_examples,
          pending_examples + other.pending_examples,
          load_time + other.load_time
      end

      def fully_formatted
        ::RSpec::Core::Notifications::SummaryNotification.new(duration, examples, failed_examples, pending_examples, load_time).fully_formatted
      end

      def failure_count
        failed_examples.size
      end

      def self.from_notification(summary)
        serialized_examples = [summary.examples, summary.failed_examples, summary.pending_examples].map do |examples|
          examples.map(&Example.method(:new))
        end

        new summary.duration, *serialized_examples, summary.load_time
      end
    end
  end
end
