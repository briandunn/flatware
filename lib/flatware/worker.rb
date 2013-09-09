require 'flatware/cucumber'
require 'flatware/fireable'
require 'flatware/sink/client'
module Flatware
  class Worker
    attr_reader :id

    def initialize(id, dispatch_endpoint, sink_endpoint)
      $0        = "flatware worker #{id}"
      @id       = id
      @fireable = Fireable.new
      @sink     = Sink::Client.new sink_endpoint
      @task     = Flatware.socket ZMQ::REQ, connect: dispatch_endpoint
    end

    def self.listen(*args)
      new(ENV['TEST_ENV_NUMBER'].to_i,*args).listen
    end

    def self.spawn(worker_count, dispatch_endpoint, sink_endpoint)
      worker_count.times do |i|
        Kernel.spawn({'TEST_ENV_NUMBER' => i.to_s}, <<-CMD.gsub("\n", ' '))
          ruby -I#{Pathname.new(__FILE__).dirname.expand_path.join '..' }
          -r#{__FILE__}
          -e 'Flatware.verbose = #{Flatware.verbose?}'
          -e 'Flatware::Worker.listen "#{dispatch_endpoint}", "#{sink_endpoint}"' >> #{i}.log 2>&1
        CMD
      end
    end

    def listen
      Sink.client = sink
      report_for_duty
      fireable.until_fired task do |job|
        job.worker = id
        sink.started job
        Cucumber.run job.id, job.args
        sink.finished job
        report_for_duty
      end
    end

    private

    attr_reader :fireable, :task, :sink

    def report_for_duty
      task.send 'ready'
    end
  end
end
