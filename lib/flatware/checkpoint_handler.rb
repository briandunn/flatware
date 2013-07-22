module Flatware
  class CheckpointHandler
    def initialize(out, fails_fast)
      @fail_fast = fails_fast
      @out = out
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

    def summarize
      summary.summarize
    end

    def steps
      @steps ||= @checkpoints.map(&:steps).flatten
    end

    def scenarios
      @scenarios ||= @checkpoints.map(&:scenarios).flatten
    end

    def summary
      @summary ||= Summary.new(steps, scenarios, @out)
    end

    def had_failures?
      summary.had_failures?
    end
  end
end
