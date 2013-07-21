module Flatware
  class CheckpointHandler
    attr_reader :formatter, :checkpoints

    def initialize(formatter, fails_fast)
      @fail_fast = fails_fast
      @formatter = formatter
      @checkpoints = []
    end

    def handle!(checkpoint)
      checkpoints << checkpoint
      if checkpoint.failures? && fail_fast?
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

    def had_failures?
      scenarios.any? { |s| s.status == :failed }
    end

    def summarize
      formatter.summarize(steps, scenarios)
    end

    private

    def steps
      checkpoints.map(&:steps).flatten
    end

    def scenarios
      checkpoints.map(&:scenarios).flatten
    end
  end
end
