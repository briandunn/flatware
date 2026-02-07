module Flatware
  module Cucumber
    class Result
      attr_reader :progress, :worker

      def initialize(progress)
        @progress = progress
        @worker   = ENV.fetch('TEST_ENV_NUMBER', 0).to_i
      end

      class << self
        def step(*)
          step = StepResult.new(*)
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
end
