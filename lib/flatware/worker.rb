require 'benchmark'
module Flatware
  class Worker
    class << self

      def fireable
        @fireable ||= Fireable.new
      end

      def task
        @task ||= Flatware.socket(ZMQ::REQ).tap do |task|
          task.connect Dispatcher::DISPATCH_PORT
        end
      end

      def report_for_duty
        task.send 'ready'
      end

      def listen!(worker_number='')
        time = Benchmark.realtime do
          ENV['TEST_ENV_NUMBER'] = worker_number.to_s
          fireable
          report_for_duty
          fireable.until_fired task do |work|
            log 'working!'
            Cucumber.run work
            Sink.finished work
            report_for_duty
            log 'waiting'
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
