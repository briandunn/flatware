module Flatware
  class StepResult
    attr_reader :status, :exception, :scenario_id

    def initialize(status, exception, scenario_id=nil)
      @status, @exception, @scenario_id = status, serialized(exception), scenario_id
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

    class SerializedException
      attr_reader :class, :message, :backtrace
      def initialize(klass, message, backtrace)
        @class, @message, @backtrace = serialized(klass), message, backtrace
      end

      private
      def serialized(klass)
        SerializedClass.new(klass.to_s)
      end
    end

    class SerializedClass
      attr_reader :name
      alias to_s name
      def initialize(name); @name = name end
    end
  end
end
