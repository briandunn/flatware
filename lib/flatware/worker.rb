# frozen_string_literal: true

require 'drb/drb'

module Flatware
  require 'flatware/configuration'
  # executes tests and sends results to the sink
  class Worker
    attr_reader :sink, :runner, :id

    def initialize(id, runner, sink_endpoint)
      @id       = id
      @runner   = runner
      @sink     = DRbObject.new_with_uri sink_endpoint
      Flatware::Sink.client = @sink
    end

    def self.spawn(count:, runner:, sink:, **)
      Flatware.configuration.before_fork.call
      count.times do |i|
        fork do
          $0 = "flatware worker #{i}"
          ENV['TEST_ENV_NUMBER'] = i.to_s
          Flatware.configuration.after_fork.call(i)
          new(i, runner, sink).listen
        end
      end
    end

    def listen
      retrying(times: 10, wait: 0.1) do
        job = sink.ready id
        until want_to_quit? || job.sentinel?
          job.worker = id
          sink.started job
          run job
          job = sink.ready id
        end
      end
    end

    private

    def run(job)
      runner.run job.id, job.args
      sink.finished job
    rescue Interrupt
      want_to_quit!
    rescue StandardError => e
      Flatware.log e
      job.failed!
      sink.finished job
    end

    def want_to_quit!
      @want_to_quit = true
    end

    def want_to_quit?
      @want_to_quit == true
    end

    def retrying(times:, wait:)
      tries = 0
      begin
        yield unless want_to_quit?
      rescue DRb::DRbConnError => e
        raise if (tries += 1) >= times

        sleep wait
        Flatware.log('retrying', e.message)
        retry
      end
    end
  end
end
