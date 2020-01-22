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
        loop do
          break if @want_to_quit
          job = sink.ready self
          break if (job == 'seppuku')

          job.worker = id
          run job

        rescue Interrupt
          @want_to_quit = true
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
      tries = 1
      begin
        yield unless @want_to_quit
      rescue DRb::DRbConnError
        raise if tries >= times

        tries += 1

        sleep wait
        retry
      end
    end
  end
end
