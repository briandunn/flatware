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
      steps = @checkpoints.map(&:steps).flatten
      scenarios = @checkpoints.map(&:scenarios).flatten
      Summary.new(steps, scenarios, @out).summarize
    end
  end
end
