module Flatware
  module RSpec
    module Marshalable
      class SharedGroupInclusionBacktrace < ::RSpec::Core::SharedExampleGroupInclusionStackFrame
        def self.from_rspec(backtrace)
          new(backtrace.shared_group_name.to_s, backtrace.inclusion_location)
        end
      end
    end
  end
end
