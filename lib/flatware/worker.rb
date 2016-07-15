require 'flatware/sink/client'
module Flatware
  class Worker
    attr_reader :id

    def initialize(id, runner, dispatch_endpoint, sink_endpoint)
      @id       = id
      @runner   = runner
      @sink     = Sink::Client.new sink_endpoint
      @task     = Flatware.socket ZMQ::REQ, connect: dispatch_endpoint
    end

    def self.spawn(count:, runner:, dispatch:, sink:)
      count.times do |i|
        fork do
          $0 = "flatware worker #{i}"
          ENV['TEST_ENV_NUMBER'] = i.to_s
          new(i, runner, dispatch, sink).listen
        end
      end
    end

    def listen
      trap 'INT' do
        Flatware.close!
        @want_to_quit = true
        exit(1)
      end

      Sink.client = sink
      report_for_duty
      loop do
        job = task.recv
        break if job == 'seppuku' or @want_to_quit
        job.worker = id
        sink.started job
        begin
          runner.run job.id, job.args
        rescue => e
          Flatware.log e
          job.failed = true
        end
        sink.finished job
        report_for_duty
      end
      Flatware.close unless @want_to_quit
    end

    private

    attr_reader :fireable, :task, :sink, :runner

    def report_for_duty
      task.send [:ready, id]
    end
  end
end
