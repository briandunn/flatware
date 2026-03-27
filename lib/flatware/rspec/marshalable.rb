module Flatware
  module RSpec
    module Marshalable
      require 'flatware/rspec/marshalable/deprecation_notification'
      require 'flatware/rspec/marshalable/examples_notification'
      require 'flatware/rspec/marshalable/example_notification'
      require 'flatware/rspec/marshalable/profile_notification'
      require 'flatware/rspec/marshalable/summary_notification'

      module_function

      def for_event(event)
        {
          dump_pending: ExamplesNotification,
          dump_failures: ExamplesNotification,
          dump_profile: ProfileNotification,
          dump_summary: SummaryNotification,
          deprecation: DeprecationNotification
        }.fetch(event)
      end
    end
  end
end
