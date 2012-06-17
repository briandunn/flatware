module Flatware
  class Worker
    class << self

      def context
        @context ||= ZMQ::Context.new
      end

      def die
        @die ||= context.socket(ZMQ::SUB).tap do |die|
          die.connect 'ipc://die'
          die.setsockopt ZMQ::SUBSCRIBE, ''
        end
      end

      def task
        @task ||= context.socket(ZMQ::REQ).tap do |task|
          task.connect 'ipc://dispatch'
        end
      end

      def listen_to_boss
        die
      end

      def clock_in
        task.send 'hi'
      end

      def close_up
        [die, task, context].each &:close
      end

      def listen!
        clock_in
        listen_to_boss
        die.recv
        close_up
      end
    end
  end
end
