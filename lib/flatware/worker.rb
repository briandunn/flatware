# frozen_string_literal: true

require 'drb/drb'

module Flatware
  # executes tests and sends results to the sink
  class Worker
    attr_reader :sink, :runner, :id

    def initialize(id, runner, sink_endpoint)
      @id       = id
      @runner   = runner
      @sink     = DRbObject.new_with_uri sink_endpoint
      Flatware::Sink.client = @sink

      trap 'INT' do
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
      retrying(times: 10, wait: 0.1) do
        loop do
          job = sink.ready id
          break if (job == 'seppuku') || @want_to_quit

          job.worker = id
          run job
        end
      end
    end

    private

    def run(job)
      sink.started job
      begin
        runner.run job.id, job.args
      rescue StandardError => e
        Flatware.log e
        job.failed = true
      end
      sink.finished job
    end

    def retrying(times:, wait:)
      tries = 0
      begin
        yield
      rescue DRb::DRbConnError
        tries += 1
        if tries < times
          sleep wait
          retry
        end
      end
    end
  end
end
