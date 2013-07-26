module Flatware
  class CheckpointHandler
    extend Forwardable
    def_delegators :summary, :had_failures?

    attr_reader :checkpoints, :out
    def initialize(out, fails_fast)
      @fail_fast, @out = fails_fast, out
      @checkpoints = []
    end

    def handle!(checkpoint)
      @checkpoints << checkpoint
      if checkpoint.failures? && @fail_fast
        Fireable::kill # Killing everybody
        @done = true
      end
    end

    def done?
      @done
    end

    def fail_fast?
      @fail_fast
    end

    def summarize
      summary.summarize
    end

    private

    def summary
      @summary ||= Summary.new(steps, scenarios, out)
    end

    def steps
      checkpoints.map(&:steps).flatten
    end

    def scenarios
      checkpoints.map(&:scenarios).flatten
    end
  end
end
