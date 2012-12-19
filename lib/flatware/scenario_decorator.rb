module Flatware
  class ScenarioDecorator
    attr_reader :status

    def initialize(scenario)
      @scenario, @status = scenario, scenario.status
      @scenario = scenario.scenario_outline if example_row?
    end

    def name
      @scenario.name
    end

    def file_colon_line
      @scenario.file_colon_line
    end

    private

    def example_row?
      @scenario.respond_to? :scenario_outline
    end
  end
end
