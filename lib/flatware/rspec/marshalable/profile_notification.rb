require 'flatware/rspec/marshalable/example'
require 'flatware/rspec/marshalable/example_group'

module Flatware
  module RSpec
    module Marshalable
      class ProfileNotification < ::RSpec::Core::Notifications::ProfileNotification
        attr_reader :example_groups

        def +(other)
          self.class.new(
            duration + other.duration,
            examples + other.examples,
            number_of_examples,
            example_groups.merge(other.example_groups)
          )
        end

        def self.from_notification(rspec_notification)
          new(
            rspec_notification.duration,
            rspec_notification.examples.map(&Example.method(:new)),
            rspec_notification.number_of_examples,
            rspec_notification.instance_variable_get(:@example_groups).transform_keys(&ExampleGroup.method(:new))
          )
        end
      end
    end
  end
end
