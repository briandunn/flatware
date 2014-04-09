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
      formatter.summarize(checkpoints)
    end

    def had_failures?
      checkpoints.any? &:failures?
    end
  end
end
