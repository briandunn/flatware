require 'benchmark'
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

      def listen!(worker_number='')
        time = Benchmark.realtime do
          ENV['TEST_ENV_NUMBER'] = worker_number.to_s
          fireable
          clock_in
          fireable.until_fired task do |message|
            log 'working!'
            Cucumber.run message
            log 'waiting'
            task.send 'done'
          end
        end
        log time
      end

      private
      def log(*args)
        Flatware.log *args
      end
    end
  end
end
