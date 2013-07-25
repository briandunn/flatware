module Flatware
  class Worker
    attr_reader :id

    def self.listen!(id=0)
      new(id).listen
    end

    def initialize(id)
      @id       = id
      @fireable = Fireable.new
      @task     = Flatware.socket ZMQ::REQ, connect: Dispatcher::PORT
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
      report_for_duty
      fireable.until_fired task do |job|
        job.worker = id
        Sink.started job
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
