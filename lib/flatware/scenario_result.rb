module Flatware
  class ScenarioResult
    attr_reader :status
    def initialize(status)
      @status = status
    end

    def passed?
      status == :passed
    end

    def failed?
      status == :failed
    end
  end
end
