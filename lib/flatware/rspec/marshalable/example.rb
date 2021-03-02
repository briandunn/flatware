module Flatware
  module RSpec
    module Marshalable
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
          super(*members.map do |attribute|
            rspec_example.public_send(attribute)
          end)

          @metadata = rspec_example.metadata.slice(:extra_failure_lines, :shared_group_inclusion_backtrace)
        end

        attr_reader :metadata
      end
    end
  end
end
