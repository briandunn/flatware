require 'rspec/core/notifications'
require 'flatware/rspec/marshalable/example'

module Flatware
  module RSpec
    module Marshalable
      class SummaryNotification < ::RSpec::Core::Notifications::SummaryNotification
        def +(other)
          values = to_h.map do |key, value|
            if %i[duration load_time].include?(key)
              [value, other.public_send(key)].max
            else
              value + other.public_send(key)
            end
          end

          self.class.new(*values)
        end

        def failures?
          [failure_count, errors_outside_of_examples_count].any?(&:positive?)
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
