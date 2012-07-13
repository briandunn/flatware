require 'drb/drb'
require 'cucumber'
URI = "druby://127.0.0.1:8990"
module Flatware
  class DRbServer
    attr_reader :workers
    def initialize(workers)
      @workers = workers
    end

    def run(args, out_stream, error_stream)
      fork { Dispatcher.start Cucumber.jobs args, out_stream, error_stream }
      workers.times {|i| fork { Worker.listen! i } }
      Sink.start_server out_stream, error_stream
      Process.waitall
    end

    def self.start(workers)
      DRb.start_service URI, new(workers)
      DRb.thread.join
    end
  end
end
