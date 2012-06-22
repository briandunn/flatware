module Flatware
  class Worker
    class << self

      def fireable
        @fireable ||= Fireable.new
      end

      def task
        @task ||= Flatware.socket(ZMQ::REQ).tap do |task|
          task.connect 'ipc://dispatch'
        end
      end

      def clock_in
        task.send 'hi'
      end

      def listen!
        fireable
        clock_in
        fireable.until_fired task do |message|
          Cucumber.run message, $stdout, $stderr
          task.send 'done'
        end
      end

      private
      def log(*args)
        Flatware.log *args
      end
    end
  end
end
