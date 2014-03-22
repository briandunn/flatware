require 'flatware/serialized_exception'
module Flatware
  module Cucumber
    class StepResult
      attr_reader :status, :exception

      def initialize(status, exception)
        @status, @exception = status, serialized(exception)
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
        SerializedException.new(e.class, e.message, e.backtrace) if e
      end
    end
  end
end
