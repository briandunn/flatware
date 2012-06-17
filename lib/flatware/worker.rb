module Flatware
  class Worker
    class << self

      def context
        @context ||= ZMQ::Context.new
      end

      def fireable
        @fireable ||= Fireable.new(context)
      end

      def task
        @task ||= context.socket(ZMQ::REQ).tap do |task|
          task.connect 'ipc://dispatch'
        end
      end

      def clock_in
        task.send 'hi'
      end

      def close_up
        [task, context].each &:close
      end

      def listen!
        clock_in
        fireable.until_fired task do |message|
          Cucumber.run message, $stdout, $stderr
          task.send 'done'
        end
        puts Cucumber::Formatter.all_summaries
        close_up
      end
    end
  end

  class Fireable
    def initialize(context)
      @die = context.socket(ZMQ::SUB).tap do |die|
        die.connect 'ipc://die'
        die.setsockopt ZMQ::SUBSCRIBE, ''
      end
    end

    attr_reader :die

    def until_fired(sockets=[], &block)
      quit = false
      while !quit && (ready = ZMQ.select(Array(sockets) + [die]))
        messages = ready.flatten.compact.map(&:recv)
        return if messages.include? 'seppuku'
        messages.each &block
      end
    ensure
      die.close
    end
  end
end
