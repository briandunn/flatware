module Flatware
  class ScenarioResult
    attr_reader :id, :steps

    def initialize(id, steps=[])
      @id = id
      @steps = steps
    end

    def status
      first(:failed) || first(:undefined) || :passed
    end

    private

    def first(status)
      statuses.detect {|s| s == status}
    end

    def statuses
      steps.map &:status
    end
  end
end
