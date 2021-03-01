require 'flatware/rspec/marshalable/example_notification'

module Flatware
  module RSpec
    module Marshalable
      class ExamplesNotification
        attr_reader :failure_notifications

        def initialize(failure_notifications)
          @failure_notifications = failure_notifications
                                   .map(&ExampleNotification.method(:new))
        end

        def self.from_notification(rspec_notification)
          new rspec_notification.failure_notifications
        end

        def +(other)
          self.class.new failure_notifications + other.failure_notifications
        end

        def fully_formatted_failed_examples(*)
          formatted = "\n\nFailures:\n"
          failure_notifications.each_with_index do |failure, index|
            formatted << failure.fully_formatted(index.next)
          end
          formatted
        end
      end
    end
  end
end
