module Flatware
  class Worker
    attr_reader :sink, :runner, :tries, :id

    def initialize(id, runner, sink_endpoint)
      @id       = id
      @runner   = runner
      @sink     = DRbObject.new_with_uri sink_endpoint
      Flatware::Sink.client = @sink

      @tries = 0

      trap 'INT' do
        Flatware.close!
        @want_to_quit = true
        exit(1)
      end
    end

    def self.spawn(count:, runner:, sink:, **)
      count.times do |i|
        fork do
          $0 = "flatware worker #{i}"
          ENV['TEST_ENV_NUMBER'] = i.to_s
          new(i, runner, sink).listen
        end
      end
    end

    def listen
      loop do
        job = sink.ready id
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
      end
      Flatware.close unless @want_to_quit
    rescue DRb::DRbConnError
      @tries += 1
      if @tries < 10
        sleep 0.1
        retry
      end
    end
  end
end
