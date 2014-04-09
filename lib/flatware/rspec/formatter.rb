module Flatware
  module RSpec
    class Formatter

      METHODS = %i[full_description location execution_result example_group]
      Result = Struct.new(*METHODS)
      def initialize(stdout)
      end

      %w[example_passed example_pending example_failed].each do |message|
        define_method message do |argument|
          Sink::client.push message, serialize(argument)
        end
      end

      #full_description
      #location
      #execution_result[:run_time]
      #execution_result[:pending_message]
      #execution_result[:exception]
      #execution_result[:pending_fixed]
      #example_group
      #example_group.parent_groups
      #example_group.metadata[:example_group][:location]
      #example_group.metadata[:shared_group_name]
      def serialize(result)
        values = METHODS.map do |method|
          result.send method
        end
        result = Result.new values
        result.example_group = nil
      end
    end
  end
end
