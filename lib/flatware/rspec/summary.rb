require 'rspec/core/notifications'
module Flatware
  module RSpec
    class Example
      attr_reader :location_rerun_argument, :full_description
      def initialize(rspec_example)
        @full_description        = rspec_example.full_description
        @location_rerun_argument = rspec_example.location_rerun_argument
      end
    end

    class Summary < ::RSpec::Core::Notifications::SummaryNotification
      def +(other)
        self.class.new(*zip(other).map { |a, b| a + b })
      end

      def self.from_notification(summary)
        serialized_examples = [
          summary.examples,
          summary.failed_examples,
          summary.pending_examples
        ].map do |examples|
          examples.map(&Example.method(:new))
        end

        new summary.duration, *serialized_examples, *summary.to_a[4..-1]
      end
    end
  end
end
