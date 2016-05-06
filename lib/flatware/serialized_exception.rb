module Flatware
  class SerializedException
    attr_reader :class, :message
    attr_accessor :backtrace
    def initialize(klass, message, backtrace)
      @class, @message, @backtrace = serialized(klass), message, backtrace
    end

    def self.from(exception)
      new exception.class, exception.message, exception.backtrace
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
