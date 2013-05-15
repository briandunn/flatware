require 'flatware/scenario_result'
module Flatware
  class Checkpoint
    attr_reader :steps, :scenarios
    def initialize(steps, scenarios)
      @steps, @scenarios = serialize_steps(steps), serialize_scenarios(scenarios)
    end

    def failures?
      scenarios.any? &:failed?
    end

    private

    def serialize_steps(steps)
      steps.map do |step|
        StepResult.new step.status, step.exception
      end
    end

    def serialize_scenarios(scenarios)
      scenarios.map do |scenario|
        ScenarioResult.new scenario.status, scenario.file_colon_line, scenario.name
      end
    end

  end
end
