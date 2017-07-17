require 'flatware/serialized_exception'
module Flatware
  module Cucumber
    class StepResult
      attr_reader :status, :exception, :seconds

      def initialize(status, exception, nanoseconds)
        @status = status
        @exception = (serialized(exception) if exception)
        @seconds = nanoseconds / 1_000_000_000.0
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
      def serialized(e)
        e.backtrace and e.backtrace.unshift e.backtrace.shift.sub(Dir.pwd, '.')
        SerializedException.new(e.class, e.message, e.backtrace)
      end
    end
  end
end
