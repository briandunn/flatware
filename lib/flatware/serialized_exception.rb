module Flatware
  class SerializedException
    attr_reader :class, :message, :cause
    attr_accessor :backtrace

    def initialize(klass, message, backtrace, cause = '')
      @class = serialized(klass)
      @message = message
      @backtrace = backtrace
      @cause = cause
    end

    def self.from(exception)
      new(
        exception.class,
        exception.message,
        exception.backtrace,
        exception.cause
      )
    end

    private

    def serialized(klass)
      SerializedClass.new(klass.to_s)
    end
  end

  class SerializedClass
    attr_reader :name
    alias to_s name
    def initialize(name)
      @name = name
    end
  end
end
