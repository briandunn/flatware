module Flatware
  module RSpec
    module Marshalable
      class DeprecationNotification < ::RSpec::Core::Notifications::SeedNotification
        def self.from_rspec(notification)
          notification
        end
      end
    end
  end
end
