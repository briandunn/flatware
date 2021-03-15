module Flatware
  module RSpec
    module Marshalable
      require 'flatware/serialized_exception'
      class ExecutionResult < ::RSpec::Core::Example::ExecutionResult
        def self.from_rspec(result)
          new.tap do |marshalable|
            marshalable.exception = result.exception && SerializedException.from(result.exception)

            %i[finished_at run_time started_at status].each do |member|
              marshalable.public_send(:"#{member}=", result.public_send(member))
            end
          end
        end
      end
    end
  end
end
