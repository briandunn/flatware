require 'cucumber'

module Flatware
  module Cucumber
    # Cucumber memoizes the feature files to run, so a runtime reused across
    # jobs needs them cleared whenever it is reconfigured. Its formatters are
    # memoized too, and must be kept: they are what carries results across jobs.
    class Runtime < ::Cucumber::Runtime
      def configure(new_configuration)
        super
        @features = nil
        @filespecs = nil
      end
    end
  end
end
