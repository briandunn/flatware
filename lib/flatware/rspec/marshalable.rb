module Flatware
  module RSpec
    module Marshalable
      require 'flatware/rspec/marshalable/examples_notification'
      require 'flatware/rspec/marshalable/profile_notification'
      require 'flatware/rspec/marshalable/summary_notification'

      class PassThrough
        def self.from_rspec(notification)
          notification
        end
      end

      module_function

      def for_event(event)
        {
          dump_pending: ExamplesNotification,
          dump_failures: ExamplesNotification,
          dump_profile: ProfileNotification,
          dump_summary: SummaryNotification,
          deprecation: PassThrough,
          seed: PassThrough
        }.fetch(event)
      end
    end
  end
end
