module Flatware
  class Worker

    def self.listen!
      new.listen
    end

    def initialize
      @fireable = Fireable.new
      @task     = Flatware.socket ZMQ::REQ, connect: Dispatcher::PORT
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
      report_for_duty
      fireable.until_fired task do |job|
        Cucumber.run job.id, job.args
        Sink.finished job
        report_for_duty
      end
    end

    private

    attr_reader :fireable, :task

    def report_for_duty
      task.send 'ready'
    end
  end
end
