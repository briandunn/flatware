require 'benchmark'
module Flatware
  class Worker

    def self.listen!
      new.listen
    end

    def self.spawn(worker_count)
      worker_count.times do |i|
        fork do
          $0 = "flatware worker #{i}"
          ENV['TEST_ENV_NUMBER'] = i.to_s
          listen!
        end
      end
    end

    def listen
      time = Benchmark.realtime do
        fireable
        report_for_duty
        fireable.until_fired task do |work|
          job = Marshal.load work
          log 'working!'
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
      @task ||= Flatware.socket(ZMQ::REQ).tap do |task|
        task.connect Dispatcher::DISPATCH_PORT
      end
    end

    def report_for_duty
      task.send 'ready'
    end
  end
end
