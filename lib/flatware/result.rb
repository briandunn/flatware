module Flatware
  class Result
    attr_reader :progress, :steps

    def initialize(progress, steps=nil)
      @progress, @steps = progress, steps || []
    end

    class << self
      def step(*args)
        step = StepResult.new *args
        new step.progress, [step]
      end
    end
  end
end
