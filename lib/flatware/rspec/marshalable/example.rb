module Flatware
  module RSpec
    module Marshalable
      require 'flatware/rspec/marshalable/execution_result'
      require 'flatware/rspec/marshalable/shared_group_inclusion_backtrace'

      ##
      # a subset of the rspec example interface that can traverse drb
      Example = Struct.new(
        *%i[
          execution_result
          full_description
          location
          location_rerun_argument
        ]
      ) do
        def initialize(rspec_example)
          super(marshalable_execution_result(rspec_example.execution_result), *members[1..].map do |attribute|
            rspec_example.public_send(attribute)
          end)

          @metadata = marshalable_metadata(rspec_example.metadata)
        end

        attr_reader :metadata

        private

        def marshalable_execution_result(execution_result)
          ExecutionResult.from_rspec(execution_result)
        end

        def marshalable_metadata(rspec_metadata)
          rspec_metadata.slice(:extra_failure_lines).tap do |metadata|
            if (backtraces = rspec_metadata[:shared_group_inclusion_backtrace])
              metadata[:shared_group_inclusion_backtrace] =
                backtraces.map(&SharedGroupInclusionBacktrace.method(:from_rspec))
            end
          end
        end
      end
    end
  end
end
