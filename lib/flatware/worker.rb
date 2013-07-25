require 'benchmark'
module Flatware
  class Worker
    attr_reader :id

    def initialize(id)
      @id = id
    end

    def self.listen!(id=0)
      new(id).listen
    end

    def self.spawn(worker_count)
      worker_count.times do |i|
        fork do
          $0 = "flatware worker #{i}"
          ENV['TEST_ENV_NUMBER'] = i.to_s
          listen!(i)
        end
      end
    end

    def listen
      time = Benchmark.realtime do
        fireable
        report_for_duty
        fireable.until_fired task do |job|
          log 'working!'
          job.worker = id
          Cucumber.run job.id, job.args
          Sink.finished job
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

    def fireable
      @fireable ||= Fireable.new
    end

    def task
      @task ||= Flatware.socket ZMQ::REQ, connect: Dispatcher::PORT
    end

    def report_for_duty
      task.send 'ready'
    end
  end
end
