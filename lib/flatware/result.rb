module Flatware
  class Result
    attr_reader :progress, :worker

    def initialize(progress)
      @progress = progress
      @worker   = ENV['TEST_ENV_NUMBER'].to_i
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
