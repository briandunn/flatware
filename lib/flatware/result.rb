module Flatware
  class Result
    attr_reader :progress

    def initialize(progress)
      @progress = progress
    end

    class << self
      def step(*args)
        step = StepResult.new *args
        new step.progress, [step]
      end

      def status(status)
        new status
      end

      def background(status, exception)
        new '', [StepResult.new(status, exception)]
      end
    end
  end
end
