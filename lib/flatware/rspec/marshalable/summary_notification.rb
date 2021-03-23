require 'rspec/core/notifications'
require 'flatware/rspec/marshalable/example'

module Flatware
  module RSpec
    module Marshalable
      class SummaryNotification < ::RSpec::Core::Notifications::SummaryNotification
        def +(other)
          self.class.new(*zip(other).map { |a, b| a + b })
        end

        def failures?
          [failure_count, errors_outside_of_examples_count].any?(&:positive?)
        end

        def example_paths
          examples.map do |example|
            example.location_rerun_argument.match(/^(?<path>.+):\d+$/)[:path]
          end.uniq.sort
        end

        def self.from_rspec(summary)
          serialized_examples = [
            summary.examples,
            summary.failed_examples,
            summary.pending_examples
          ].map do |examples|
            examples.map(&Example.method(:new))
          end

          new(summary.duration, *serialized_examples, *summary.to_a[4..])
        end
      end
    end
  end
end
