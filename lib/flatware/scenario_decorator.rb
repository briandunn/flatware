module Flatware
  class ScenarioDecorator
    def initialize(scenario)
      @scenario = scenario
    end

    %w(file_colon_line name).each do |get|
      define_method "#{get}" do
        @scenario.respond_to?(:scenario_outline) ? @scenario.scenario_outline.send("#{get}") : @scenario.send("#{get}")
      end
    end

    def status
      @scenario.status
    end

  end
end
