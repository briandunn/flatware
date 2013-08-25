require 'benchmark'
module Flatware
  class Worker
    attr_reader :id, :task

    def initialize(id)
      @id = id
      @task = Flatware.socket ZMQ::REQ, connect: Sink::DISPATCH_PORT
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
      loop do
        task.send [:ready, id]
        message, job = task.recv
        break if message == :seppuku
        job.worker = id
        Cucumber.run job.id, job.args
        Sink.finished job
      end
      Flatware.close
    end
  end
end
