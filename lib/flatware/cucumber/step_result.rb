require 'flatware/serialized_exception'
module Flatware
  module Cucumber
    class StepResult
      attr_reader :status, :exception

      def initialize(status, exception)
        @status = status
        @exception = (serialized(exception) if exception)
      end

      def passed?
        status == :passed
      end

      def failed?
        status == :failed
      end

      def progress
        Cucumber::ProgressString.format(status)
      end

      private

      def serialized(err)
        err.backtrace&.unshift(err.backtrace.shift.sub(Dir.pwd, '.'))
        SerializedException.new(err.class, err.message, err.backtrace)
      end
    end
  end
end
