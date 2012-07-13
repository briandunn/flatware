require 'benchmark'
module Flatware
  class Worker

    def self.listen!(worker_number='')
      new(worker_number).listen
    end

    def initialize(worker_number)
      @worker_number = worker_number.to_s
      ENV['TEST_ENV_NUMBER'] = @worker_number
    end

    def listen
      time = Benchmark.realtime do
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

    attr_reader :worker_number

    def log(*args)
      Flatware.log *args
    end

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
  end
end
